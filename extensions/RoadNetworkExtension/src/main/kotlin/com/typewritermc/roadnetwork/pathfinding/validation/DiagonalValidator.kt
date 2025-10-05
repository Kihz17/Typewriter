package com.typewritermc.roadnetwork.pathfinding.validation

import de.bsommerfeld.pathetic.api.pathing.processing.NodeValidationProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.NodeEvaluationContext
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.provider.BukkitNavigationPoint
import org.bukkit.World
import org.bukkit.block.BlockFace
import org.bukkit.block.data.Bisected
import org.bukkit.block.data.type.Stairs

class DiagonalValidator () : NodeValidationProcessor {

    override fun isValid(p0: NodeEvaluationContext?): Boolean {
        val currentPos = p0?.currentPathPosition ?: return false
        val prevPos = p0.previousPathPosition
        if(prevPos == null) {
            return true // First node
        }

        val dx = currentPos.flooredX - prevPos.flooredX
        val dz = currentPos.flooredZ - prevPos.flooredZ

        val isDiagonal = dx != 0 && dz != 0
        if(!isDiagonal) {
            return true // Not diag, we don't care
        }

        // Get blocks to the left and right of the diagonal move
        val side1 = prevPos.add(dx.toDouble(), 0.0, 0.0) // X step
        val side2 = prevPos.add(0.0, 0.0, dz.toDouble()) // Z step

        val sidePoint1 = p0.navigationPointProvider.getNavigationPoint(side1, p0.environmentContext)
        val sidePoint2 = p0.navigationPointProvider.getNavigationPoint(side2, p0.environmentContext)

        if(sidePoint1.isTraversable && sidePoint2.isTraversable) {
            return true
        }

        val bukkitPoint1 = sidePoint1 as? BukkitNavigationPoint ?: return false
        val bukkitPoint2 = sidePoint2 as? BukkitNavigationPoint ?: return false

        val stairs1 = bukkitPoint1.blockState.blockData as? Stairs ?: return false
        val stairs2 = bukkitPoint2.blockState.blockData as? Stairs ?: return false

        val faceX = when {
            dx > 0 -> BlockFace.EAST
            dx < 0 -> BlockFace.WEST
            else -> null
        }

        val faceZ = when {
            dz > 0 -> BlockFace.SOUTH
            dz < 0 -> BlockFace.NORTH
            else -> null
        }

        val valid1 = (stairs1.facing == faceX || stairs1.facing == faceZ) && stairs1.half == Bisected.Half.BOTTOM
        val valid2 = (stairs2.facing == faceX || stairs2.facing == faceZ) && stairs2.half == Bisected.Half.BOTTOM

        return valid1 && valid2
    }
}