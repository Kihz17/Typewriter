package com.typewritermc.roadnetwork.pathfinding

import de.bsommerfeld.pathetic.api.pathing.processing.NodeValidationProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.NodeEvaluationContext


class SimpleValidationProcessor : NodeValidationProcessor {
    override fun isValid(context: NodeEvaluationContext): Boolean {
        return context
            .pathfinderConfiguration
            .provider
            .getNavigationPoint(context.currentPathPosition, context.environmentContext)
            .isTraversable
    }
}