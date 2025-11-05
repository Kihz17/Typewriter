package com.typewritermc.entity.entries.data.minecraft

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityData
import com.typewritermc.engine.paper.extensions.packetevents.metas
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.stripped
import me.tofaa.entitylib.meta.EntityMeta
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import me.tofaa.entitylib.wrapper.WrapperPlayer
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor
import net.kyori.adventure.text.format.TextColor
import net.rpggame.quests.Quests
import net.rpggame.utils.GameUtils
import net.shared.hud.QuestType
import org.bukkit.Bukkit
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("quest_glowing_effect_data", "If the entity is glowing", Colors.RED, "bi:lightbulb-fill")
@Tags("quest_glowing_effect_data")
class QuestGlowingEffectData(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether the entity is glowing.")
    @Default("true")
    val glowing: Boolean = true,
    val questType: QuestType = QuestType.MAIN_QUEST,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : GenericEntityData<QuestGlowingEffectProperty> {

    override fun canApply(player: Player): Boolean {
        // Find the entity instance that contains this data entry
        val entityInstance = findParentEntityInstance() ?: return true

        // Get the display name from the entity's definition and strip all formatting
        val displayName = entityInstance.definition.get()?.displayName?.get(player)?.stripped() ?: return true

        // Check if player has active quest for this NPC
        return Quests.hasActiveNPCGlowData(player, displayName)
    }

    private fun findParentEntityInstance(): EntityInstanceEntry? {
        // Search for entity instances that have this data entry in their data list
        return Query.find<EntityInstanceEntry>().firstOrNull { instance ->
            instance.children.any { it.id == this.id }
        }
    }

    override fun type(): KClass<QuestGlowingEffectProperty> = QuestGlowingEffectProperty::class

    override fun build(player: Player): QuestGlowingEffectProperty = QuestGlowingEffectProperty(glowing, questType)
}

data class QuestGlowingEffectProperty(val glowing: Boolean = false, val questType: QuestType) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<QuestGlowingEffectProperty>(
        QuestGlowingEffectProperty::class,
        QuestGlowingEffectProperty(false, QuestType.MAIN_QUEST)
    )
}

fun applyGlowingEffectData(entity: WrapperEntity, property: QuestGlowingEffectProperty) {
    val info = WrapperPlayServerTeams.ScoreBoardTeamInfo(
        Component.empty(),
        null,
        null,
        WrapperPlayServerTeams.NameTagVisibility.NEVER,
        WrapperPlayServerTeams.CollisionRule.NEVER,
        property.questType.color,
        WrapperPlayServerTeams.OptionData.NONE
    )
    if (property.glowing && entity.entityMeta is AbstractDisplayMeta) {
        entity.metas {
            meta<AbstractDisplayMeta> { glowColorOverride = property.questType.color.value() }
            error("Could not apply GlowingEffectData to ${entity.entityType} entity.")
        }
    } else if (entity is WrapperPlayer) {
        entity.viewers.firstOrNull()?.let { viewerUuid ->
            Bukkit.getPlayer(viewerUuid)?.let { player ->
                WrapperPlayServerTeams(
                    "typewriter-${entity.entityId}",
                    WrapperPlayServerTeams.TeamMode.UPDATE,
                    info
                ) sendPacketTo player
            }
        }
    } else {
        entity.viewers.firstOrNull()?.let { viewerUuid ->
            Bukkit.getPlayer(viewerUuid)?.let { player ->
                WrapperPlayServerTeams(
                    "typewriter-${entity.entityId}",
                    WrapperPlayServerTeams.TeamMode.CREATE,
                    info,
                    entity.uuid.toString()
                ) sendPacketTo player
            }
        }
    }

    entity.metas {
        meta<EntityMeta> { setHasGlowingEffect(property.glowing) }
        error("Could not apply GlowingEffectData to ${entity.entityType} entity.")
    }
}