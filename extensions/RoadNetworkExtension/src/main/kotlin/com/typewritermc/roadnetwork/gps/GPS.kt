package com.typewritermc.roadnetwork.gps

import com.extollit.gaming.ai.path.HydrazinePathFinder
import com.extollit.gaming.ai.path.SchedulingPriority
import com.extollit.gaming.ai.path.model.*
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.entity.toProperty
import com.typewritermc.engine.paper.utils.toBukkitWorld
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.RoadNode
import com.typewritermc.roadnetwork.pathfinding.PFEmptyEntity
import com.typewritermc.roadnetwork.pathfinding.PFInstanceSpace
import com.typewritermc.roadnetwork.pathfinding.SimpleValidationProcessor
import com.typewritermc.roadnetwork.pathfinding.instanceSpace
import com.typewritermc.roadnetwork.pathfinding.validation.DiagonalValidator
import com.typewritermc.roadnetwork.pathfinding.validation.WalkableValidator
import com.typewritermc.roadnetwork.roadNetworkMaxDistance
import de.bsommerfeld.pathetic.api.factory.PathfinderInitializer
import de.bsommerfeld.pathetic.api.pathing.NeighborStrategies
import de.bsommerfeld.pathetic.api.pathing.Pathfinder
import de.bsommerfeld.pathetic.api.pathing.configuration.PathfinderConfiguration
import de.bsommerfeld.pathetic.api.pathing.heuristic.HeuristicWeights
import de.bsommerfeld.pathetic.api.pathing.processing.NodeValidationProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.Validators
import de.bsommerfeld.pathetic.api.pathing.result.PathfinderResult
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import de.bsommerfeld.pathetic.bukkit.initializer.BukkitPathfinderInitializer
import de.bsommerfeld.pathetic.bukkit.provider.LoadingNavigationPointProvider
import de.bsommerfeld.pathetic.engine.factory.AStarPathfinderFactory
import java.util.concurrent.CompletionStage


class TWPathfinder {
    companion object {
        var validators : NodeValidationProcessor = Validators.allOf(WalkableValidator(), DiagonalValidator() )

        private val config = PathfinderConfiguration.builder()
            .async(false)
            .provider(LoadingNavigationPointProvider())
            .fallback(true)
            .nodeValidationProcessors(listOf(SimpleValidationProcessor()))
            .neighborStrategy(NeighborStrategies.DIAGONAL_3D)
            .heuristicWeights(HeuristicWeights.create(0.0, 0.0, 2.5, 0.0))
            .nodeValidationProcessors(listOf(validators))
            .build()


        var initializer: PathfinderInitializer = BukkitPathfinderInitializer()

        val pf: Pathfinder = AStarPathfinderFactory().createPathfinder(config, initializer)
    }
}

interface GPS {
    val roadNetwork: Ref<RoadNetworkEntry>
    suspend fun findPath(): Result<List<GPSEdge>>
}

data class GPSEdge(
    val start: Position,
    val end: Position,
    val weight: Double,
    /**
     * The number of blocks the path is long.
     */
    val length: Double,
) {
    val isFastTravel: Boolean
        get() = weight == 0.0
}

fun roadNetworkFindPath(
    start: RoadNode,
    end: RoadNode,
    entity: IPathingEntity = PFEmptyEntity(start.position.toProperty(), searchRange = roadNetworkMaxDistance.toFloat()),
    instance: PFInstanceSpace = start.position.world.instanceSpace,
    nodes: List<RoadNode> = emptyList(),
    negativeNodes: List<RoadNode> = emptyList(),
): IPath? {
    return roadNetworkFindPath(start, end, HydrazinePathFinder(entity, instance), nodes, negativeNodes)
}

fun roadNetworkFindPath(
    start: RoadNode,
    end: RoadNode,
    pathfinder: HydrazinePathFinder,
    nodes: List<RoadNode> = emptyList(),
    negativeNodes: List<RoadNode> = emptyList(),
): IPath? {
    val interestingNodes = nodes.filter {
        if (it.id == start.id) return@filter false
        if (it.id == end.id) return@filter false
        true
    }
    val interestingNegativeNodes = negativeNodes.filter {
        val distance = start.position.distanceSqrt(it.position) ?: 0.0
        distance > it.radius * it.radius && distance < roadNetworkMaxDistance * roadNetworkMaxDistance
    }

    pathfinder.schedulingPriority(SchedulingPriority.extreme)
    val additionalRadius = pathfinder.subject().width().toDouble()

    // We want to avoid going through negative nodes
    if (interestingNegativeNodes.isNotEmpty()) {
        pathfinder.withGraphNodeFilter { node ->
            if (node.isInRangeOf(interestingNegativeNodes, additionalRadius)) {
                return@withGraphNodeFilter Passibility.dangerous
            }
            node.passibility()
        }
    }

    // When the pathfinder wants to go through another intermediary node, we know that we probably want to use that.
    // So we don't want this edge to be used.
    val path = pathfinder.computePathTo(end.position.x, end.position.y, end.position.z) ?: return null
    if (interestingNodes.isNotEmpty() && path.any { it.isInRangeOf(interestingNodes, additionalRadius) }) {
        return null
    }

    return path
}

fun roadNetworkFindPatheticPath(
    start: RoadNode,
    end: RoadNode,
): CompletionStage<PathfinderResult> {
    return TWPathfinder.pf.findPath(
        PathPosition(start.position.x, start.position.y, start.position.z),
        PathPosition(end.position.x, end.position.y, end.position.z),
        BukkitEnvironmentContext(start.position.world.toBukkitWorld()))
}

fun INode.isInRangeOf(roadNodes: List<RoadNode>, additionalRadius: Double = 0.0): Boolean {
    return roadNodes.any { roadNode ->
        val point = this.coordinates().toVector().mid()
        val radius = roadNode.radius + additionalRadius
        roadNode.position.toProperty().distanceSquared(point) <= radius * radius
    }
}

fun Coords.toVector() = Vector(x.toDouble(), y.toDouble(), z.toDouble())
