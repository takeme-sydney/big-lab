"""
active_learning.py
後ろ向き能動学習シミュレーション — Yuan et al. (2023) マイクロニードル
薬物透過データセット(191点・6薬剤)を用いて、能動学習による実験計画の
効率化効果を検証する。

3つの獲得戦略(acquisition strategy)を比較:
  - Random: ランダムサンプリング(ベースライン)
  - GP-Uncertainty: Gaussian Process回帰の予測分散が最大の点を選択
  - RF-QBC: Random Forestのブートストラップ委員会(Query-by-Committee)の
            予測分散が最大の点を選択

評価は固定のRandom Forest評価器で行い、獲得戦略のバイアスと評価のバイアスを
分離する(獲得に使うモデルと評価に使うモデルは別)。

RANDOM_STATE = 42 に統一(CLAUDE.md記載の規約に準拠)。
"""

import numpy as np
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import RBF, WhiteKernel, ConstantKernel
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import r2_score, mean_squared_error

RANDOM_STATE = 42


def make_gp(n_features: int) -> GaussianProcessRegressor:
    """獲得戦略用のGaussian Process回帰モデルを構築する。"""
    kernel = (
        ConstantKernel(1.0, (1e-2, 1e2))
        * RBF(length_scale=np.ones(n_features), length_scale_bounds=(1e-1, 1e2))
        + WhiteKernel(noise_level=0.1, noise_level_bounds=(1e-3, 1.0))
    )
    return GaussianProcessRegressor(
        kernel=kernel, normalize_y=True, n_restarts_optimizer=0, random_state=RANDOM_STATE
    )


def make_rf(seed: int, n_estimators: int = 150, max_depth: int = 8) -> RandomForestRegressor:
    """固定評価器・獲得戦略の両方で使うRandom Forestを構築する。"""
    return RandomForestRegressor(
        n_estimators=n_estimators, random_state=seed, n_jobs=1, max_depth=max_depth
    )


def evaluate(train_idx, test_idx, X, y, seed):
    """固定のRandom Forest評価器でtrain_idxから学習し、test_idxで評価する。"""
    ev = make_rf(seed, n_estimators=150)
    ev.fit(X[train_idx], y[train_idx])
    pred = ev.predict(X[test_idx])
    r2 = r2_score(y[test_idx], pred)
    rmse = np.sqrt(mean_squared_error(y[test_idx], pred))
    return r2, rmse


def select_random(pool_idx, train_idx, X, y, rng, batch_size):
    """ランダムサンプリング(ベースライン獲得戦略)。"""
    return list(rng.choice(pool_idx, size=min(batch_size, len(pool_idx)), replace=False))


def select_gp_uncertainty(pool_idx, train_idx, X, y, rng, batch_size):
    """Gaussian Process予測分散最大の点を選択する(uncertainty sampling)。"""
    scaler = StandardScaler().fit(X[train_idx])
    Xtr = scaler.transform(X[train_idx])
    Xpool = scaler.transform(X[pool_idx])
    gp = make_gp(n_features=X.shape[1])
    gp.fit(Xtr, y[train_idx])
    _, std = gp.predict(Xpool, return_std=True)
    order = np.argsort(-std)[:batch_size]
    return [pool_idx[i] for i in order]


def select_rf_qbc(pool_idx, train_idx, X, y, rng, batch_size, n_committee=5):
    """Random Forestブートストラップ委員会の予測分散最大の点を選択する
    (query-by-committee)。"""
    preds = np.zeros((n_committee, len(pool_idx)))
    n = len(train_idx)
    for k in range(n_committee):
        boot_idx = rng.choice(train_idx, size=n, replace=True)
        rf = make_rf(seed=1000 + k, n_estimators=60)
        rf.fit(X[boot_idx], y[boot_idx])
        preds[k] = rf.predict(X[pool_idx])
    variance = preds.var(axis=0)
    order = np.argsort(-variance)[:batch_size]
    return [pool_idx[i] for i in order]


STRATEGIES = {
    "Random": select_random,
    "GP-Uncertainty": select_gp_uncertainty,
    "RF-QBC": select_rf_qbc,
}


def run_active_learning_curve(X, y, train_idx_init, pool_idx_init, test_idx,
                                select_fn, batch_size, n_steps, eval_seed=0, acq_seed=99):
    """単一の獲得戦略について、学習曲線 [(n_train, R2, RMSE), ...] を返す。"""
    train_idx = list(train_idx_init)
    pool_idx = list(pool_idx_init)
    curve = []
    r2, rmse = evaluate(np.array(train_idx), test_idx, X, y, seed=eval_seed)
    curve.append((len(train_idx), r2, rmse))
    rng = np.random.RandomState(acq_seed)
    for _ in range(n_steps):
        if len(pool_idx) == 0:
            break
        picked = select_fn(pool_idx, np.array(train_idx), X, y, rng, batch_size)
        train_idx.extend(picked)
        pool_idx = [i for i in pool_idx if i not in set(picked)]
        r2, rmse = evaluate(np.array(train_idx), test_idx, X, y, seed=eval_seed)
        curve.append((len(train_idx), r2, rmse))
    return curve
