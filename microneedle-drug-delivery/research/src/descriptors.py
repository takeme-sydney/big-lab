"""
descriptors.py
分子記述子の計算モジュール — 美容成分の皮膚透過性QSARプロジェクト用。

RDKitを用いて、SMILES文字列から皮膚透過性予測に使用する分子記述子を計算する。
Yuan et al. (2023) のマイクロニードル透過予測モデルおよび Potts & Guy (1992) の
古典的QSAR式と互換性のある記述子セットを採用している。
"""

from rdkit import Chem
from rdkit.Chem import Descriptors, Crippen, rdMolDescriptors


def canon_smiles(smiles: str) -> str | None:
    """SMILESを正規化する。パース不可の場合はNoneを返す。"""
    mol = Chem.MolFromSmiles(smiles)
    return Chem.MolToSmiles(mol) if mol else None


def compute_descriptors(smiles: str) -> dict | None:
    """
    単一のSMILESから分子記述子を計算する。

    Returns:
        dict: MW, LogP, TPSA, HBD, HBA, RotB, NumRings, NumAromaticRings,
              FractionCSP3, MolarRefractivity, NumHeteroatoms を含む辞書。
              パース失敗時はNone。
    """
    mol = Chem.MolFromSmiles(smiles)
    if mol is None:
        return None
    return {
        "MW": Descriptors.MolWt(mol),
        "LogP": Crippen.MolLogP(mol),
        "TPSA": rdMolDescriptors.CalcTPSA(mol),
        "HBD": rdMolDescriptors.CalcNumHBD(mol),
        "HBA": rdMolDescriptors.CalcNumHBA(mol),
        "RotB": rdMolDescriptors.CalcNumRotatableBonds(mol),
        "NumRings": rdMolDescriptors.CalcNumRings(mol),
        "NumAromaticRings": rdMolDescriptors.CalcNumAromaticRings(mol),
        "FractionCSP3": rdMolDescriptors.CalcFractionCSP3(mol),
        "MolarRefractivity": Crippen.MolMR(mol),
        "NumHeteroatoms": rdMolDescriptors.CalcNumHeteroatoms(mol),
    }


def potts_guy_baseline(logp: float, mw: float) -> float:
    """
    Potts & Guy (1992) の古典的皮膚透過性QSAR式によるベースライン予測。
    log Kp = -2.7 + 0.71*logP - 0.0061*MW  (Kp単位: cm/h)

    新規モデルの性能比較用ベースラインとして使用する。
    """
    return -2.7 + 0.71 * logp - 0.0061 * mw


def check_applicability_domain(mw: float, logp: float, mw_range: tuple, logp_range: tuple) -> bool:
    """訓練データの化学空間範囲(MW・LogP)内かどうかを判定する。"""
    return (mw_range[0] <= mw <= mw_range[1]) and (logp_range[0] <= logp <= logp_range[1])
