package com.typewritermc.roadnetwork.pathfinding.validation

import de.bsommerfeld.pathetic.api.pathing.processing.NodeValidationProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.NodeEvaluationContext
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.provider.BukkitNavigationPoint
import org.bukkit.World

class WalkableValidator () : NodeValidationProcessor {

    override fun isValid(p0: NodeEvaluationContext?): Boolean {
        val currentPos = p0?.currentPathPosition ?: return false

        // Can't move to nodes without something walkable underneath
        val belowPoint = p0.navigationPointProvider.getNavigationPoint(
            PathPosition(
                currentPos.x,
                currentPos.y - 1,
                currentPos.z
            ),
            p0.environmentContext
        ) as? BukkitNavigationPoint

        return belowPoint?.material?.isSolid == true && p0.navigationPointProvider.getNavigationPoint(currentPos, p0.environmentContext).isTraversable
    }
}