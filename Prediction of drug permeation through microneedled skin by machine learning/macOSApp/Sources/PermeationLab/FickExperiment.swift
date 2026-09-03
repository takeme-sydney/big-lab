import Foundation

struct FickPreviewConfiguration: Equatable, Sendable {
    var diffusionCoefficient = 700.0
    var needleCount = 64
    var needleLength = 1_000.0
    var loadedMass = 1_637.0
    /// Data S2 hard-codes 50 hours, while the paper's stated experimental range
    /// ends at 48 hours. The UI calls this source discrepancy out.
    var durationHours = 50.0

    /// The SI2 example uses a 250 µm half-domain and a 75 µm half-width.
    let skinThickness = 1_000.0
    let halfDomainWidth = 250.0
    let needleHalfWidth = 75.0

    /// An interactive preview is intentionally coarser than Data S2's 2 µm grid.
    /// The published grid would require tens of billions of cell updates at long durations.
    /// 25 µm exactly divides the 1,000 µm depth, 250 µm half-domain,
    /// and 75 µm needle half-width used by the source example.
    let gridSize = 25.0
}

struct FickPreviewPoint: Identifiable, Equatable, Sendable {
    let timeHours: Double
    let permeatedAmount: Double

    var id: Double { timeHours }
}

struct FickPreviewResult: Equatable, Sendable {
    let points: [FickPreviewPoint]
    let finalAmount: Double
    let finalPercentage: Double
    let actualTimeStepMinutes: Double
    let iterationCount: Int
    let gridColumns: Int
    let gridRows: Int
    let elapsedSeconds: Double
    let remainingMass: Double
    /// `loadedMass - (remainingMass + permeatedAmount)`. A value near zero
    /// confirms conservation for the discrete grid without clipping the result.
    let massBalanceError: Double
}

enum FickPreviewError: LocalizedError, Equatable {
    case invalidConfiguration
    case iterationLimitExceeded
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: "The Fick preview configuration is invalid."
        case .iterationLimitExceeded: "The Fick preview would exceed the interactive iteration limit."
        case .cancelled: "The Fick preview was cancelled."
        }
    }
}

/// A grid-consistent Swift reconstruction of the explicit two-dimensional update
/// pattern in Data S2. It retains the half-domain symmetry and perfect receptor
/// sink, while normalizing discrete mass and using dimensionally correct sink flux
/// on a documented coarse grid with a stability-selected time step.
enum FickPreviewEngine {
    static func run(_ configuration: FickPreviewConfiguration) throws -> FickPreviewResult {
        let started = ContinuousClock.now
        let d = configuration.diffusionCoefficient
        let dx = configuration.gridSize
        let dy = configuration.gridSize
        let durationMinutes = configuration.durationHours * 60

        guard d > 0,
              d.isFinite,
              configuration.needleCount > 0,
              configuration.needleLength > 0,
              configuration.needleLength.isFinite,
              configuration.loadedMass > 0,
              configuration.loadedMass.isFinite,
              durationMinutes > 0,
              durationMinutes.isFinite,
              dx > 0,
              dx.isFinite,
              configuration.skinThickness.isFinite,
              configuration.halfDomainWidth.isFinite,
              configuration.needleHalfWidth > 0,
              configuration.needleHalfWidth.isFinite else {
            throw FickPreviewError.invalidConfiguration
        }

        let depthCount = Int((configuration.skinThickness / dx).rounded()) + 1
        let widthCount = Int((configuration.halfDomainWidth / dy).rounded()) + 1
        guard depthCount >= 3, widthCount >= 3 else {
            throw FickPreviewError.invalidConfiguration
        }

        // For the explicit 2D scheme, alphaX + alphaY must not exceed 0.5.
        // A 0.45 safety factor avoids a marginal floating-point boundary.
        let stableTimeStep = 0.45 / (d * ((1 / (dx * dx)) + (1 / (dy * dy))))
        let requestedIterations = ceil(durationMinutes / stableTimeStep)
        guard requestedIterations.isFinite, requestedIterations <= 100_000 else {
            throw FickPreviewError.iterationLimitExceeded
        }
        let iterationCount = max(1, Int(requestedIterations))
        let dt = durationMinutes / Double(iterationCount)
        let alphaX = dt * d / (dx * dx)
        let alphaY = dt * d / (dy * dy)

        let cellCount = depthCount * widthCount
        var concentration = Array(repeating: 0.0, count: cellCount)
        var next = concentration
        let needleDepthCells = configuration.needleLength / dx
        let needleWidthCells = configuration.needleHalfWidth / dy

        @inline(__always) func offset(_ depth: Int, _ width: Int) -> Int {
            depth * widthCount + width
        }

        var loadedCellIndices: [Int] = []
        for depth in 0..<depthCount {
            for width in 0..<widthCount {
                let boundary = -(needleDepthCells / needleWidthCells) * Double(width)
                    + needleDepthCells
                if Double(depth) < boundary {
                    loadedCellIndices.append(offset(depth, width))
                }
            }
        }
        guard !loadedCellIndices.isEmpty else { throw FickPreviewError.invalidConfiguration }

        // Data S2 derives concentration from a continuous triangle, then samples
        // it on a grid. That makes total mass change with grid size. Normalize on
        // this discrete grid so the preview starts with exactly the requested mass.
        let expandedCellArea = dx * dy * 2 * Double(configuration.needleCount)
        let initialConcentration = configuration.loadedMass
            / (Double(loadedCellIndices.count) * expandedCellArea)
        for index in loadedCellIndices {
            concentration[index] = initialConcentration
        }

        let requestedSampleCount = 61
        let sampleStride = max(1, iterationCount / (requestedSampleCount - 1))
        var permeatedHalfDomain = 0.0
        var points = [FickPreviewPoint(timeHours: 0, permeatedAmount: 0)]
        points.reserveCapacity(requestedSampleCount + 1)

        for iteration in 0..<iterationCount {
            if iteration.isMultiple(of: 2_048), Task.isCancelled {
                throw FickPreviewError.cancelled
            }

            var sinkLossHalfDomain = 0.0
            for depth in 0..<depthCount {
                let isTop = depth == 0
                let isBottom = depth == depthCount - 1
                for width in 0..<widthCount {
                    let isLeft = width == 0
                    let isRight = width == widthCount - 1
                    let index = offset(depth, width)
                    let current = concentration[index]
                    if isBottom {
                        // C is mass/area, so dt·D·C·dy/dx is mass crossing
                        // the zero-concentration receptor ghost cell.
                        sinkLossHalfDomain += dt * d * current * dy / dx
                    }

                    let depthContribution: Double
                    if isTop {
                        depthContribution = concentration[offset(depth + 1, width)] - current
                    } else if isBottom {
                        // The receptor is a perfect sink outside the bottom cell.
                        depthContribution = concentration[offset(depth - 1, width)] - (2 * current)
                    } else {
                        depthContribution = concentration[offset(depth - 1, width)]
                            + concentration[offset(depth + 1, width)]
                            - (2 * current)
                    }

                    let widthContribution: Double
                    if isLeft {
                        widthContribution = concentration[offset(depth, width + 1)] - current
                    } else if isRight {
                        widthContribution = concentration[offset(depth, width - 1)] - current
                    } else {
                        widthContribution = concentration[offset(depth, width - 1)]
                            + concentration[offset(depth, width + 1)]
                            - (2 * current)
                    }

                    next[index] = current
                        + alphaX * depthContribution
                        + alphaY * widthContribution
                }
            }

            swap(&concentration, &next)
            permeatedHalfDomain += sinkLossHalfDomain

            let completed = iteration + 1
            if completed.isMultiple(of: sampleStride) || completed == iterationCount {
                let amount = permeatedHalfDomain * 2 * Double(configuration.needleCount)
                let time = Double(completed) * dt / 60
                points.append(FickPreviewPoint(timeHours: time, permeatedAmount: amount))
            }
        }

        let finalAmount = points.last?.permeatedAmount ?? 0
        let remainingMass = concentration.reduce(0, +) * expandedCellArea
        let massBalanceError = configuration.loadedMass - (remainingMass + finalAmount)
        let elapsed = started.duration(to: .now)
        let elapsedSeconds = Double(elapsed.components.seconds)
            + Double(elapsed.components.attoseconds) / 1e18
        return FickPreviewResult(
            points: points,
            finalAmount: finalAmount,
            finalPercentage: 100 * finalAmount / configuration.loadedMass,
            actualTimeStepMinutes: dt,
            iterationCount: iterationCount,
            gridColumns: widthCount,
            gridRows: depthCount,
            elapsedSeconds: elapsedSeconds,
            remainingMass: remainingMass,
            massBalanceError: massBalanceError
        )
    }
}
