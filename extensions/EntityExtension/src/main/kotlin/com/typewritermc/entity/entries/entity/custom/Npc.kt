package com.typewritermc.entity.entries.entity.custom

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.priority
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.entity.entries.data.minecraft.QuestGlowingEffectData
import com.typewritermc.entity.entries.entity.minecraft.PlayerEntity
import net.shared.hud.QuestType
import org.bukkit.entity.Player
import java.util.*


@Entry("npc_definition", "A simplified premade npc", Colors.ORANGE, "material-symbols:account-box")
@Tags("npc_definition")
/**
 * The `NpcDefinition` class is an entry that represents a simplified premade npc.
 *
 * It has an Icon above the head when an `NpcInteractObjective` is active for a player.
 * And when the objective is being tracked, the npc will have a different icon.
 *
 * The npc also has its display name above the head.
 *
 * ## How could this be used?
 * This could be used to create a simple npc has most of the properties already set.
 */
class NpcDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    val hitSound: Var<Sound> = ConstVar(Sound.EMPTY),
    val deathSound: Var<Sound> = ConstVar(Sound.EMPTY),
    @Help("The skin of the npc.")
    val skin: Var<SkinProperty> = ConstVar(SkinProperty()),
    @OnlyTags("generic_entity_data", "living_entity_data", "lines", "player_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {

    override fun create(player: Player): FakeEntity {
        return NpcEntity(player, displayName, skin, ref())
    }
}

@Entry("npc_instance", "An instance of a simplified premade npc", Colors.YELLOW, "material-symbols:account-box")
/**
 * The `NpcInstance` class is an entry that represents an instance of a simplified premade npc.
 */
class NpcInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<NpcDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "lines", "player_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance {

    // Automatically add quest glowing effect data for MAIN_QUEST and SIDE_QUEST
    override val children: List<Ref<out AudienceEntry>>
        get() = getAllData()

    private fun getAllData(): List<Ref<out EntityData<*>>> {
        val mainQuestGlow = QuestGlowingEffectData(
            id = "${id}_main_quest_glow",
            name = "${name}_main_quest_glow",
            glowing = true,
            questType = QuestType.MAIN_QUEST,
            priorityOverride = Optional.of(100)
        ).ref()

        val sideQuestGlow = QuestGlowingEffectData(
            id = "${id}_side_quest_glow",
            name = "${name}_side_quest_glow",
            glowing = true,
            questType = QuestType.SIDE_QUEST,
            priorityOverride = Optional.of(99)
        ).ref()

        return data + listOf(mainQuestGlow, sideQuestGlow)
    }

    override suspend fun display(): AudienceFilter {
        val definition = definition.get() ?: return PassThroughFilter(ref())
        val activity = this.activity.get() ?: IdleActivity

        val definitionData = definition.data.withPriority()
        val maxDefinitionData = definitionData.maxOfOrNull { it.second } ?: 0

        // Use getAllData() instead of data to include quest glowing effects
        val instanceData = getAllData().mapNotNull {
            val entityData = it.get() ?: return@mapNotNull null
            entityData to (entityData.priority + maxDefinitionData + 1)
        }

        return SharedAudienceEntityDisplay(
            ref(),
            definition,
            activity,
            (definitionData + instanceData),
            spawnLocation,
        )
    }
}

class NpcEntity(
    player: Player,
    displayName: Var<String>,
    private val skin: Var<SkinProperty>,
    definition: Ref<out EntityDefinitionEntry>,
) : FakeEntity(player) {
    private val namePlate = NamedEntity(player, displayName, PlayerEntity(player, displayName), definition)

    init {
        consumeProperties(skin.get(player))
    }

    override val entityId: Int
        get() = namePlate.entityId

    override val state: EntityState
        get() = namePlate.state

    override fun applyProperties(properties: List<EntityProperty>) {
        if (properties.any { it is SkinProperty }) {
            namePlate.consumeProperties(properties)
            return
        }
        namePlate.consumeProperties(properties + skin.get(player))
    }

    override fun tick() {
        namePlate.tick()
    }

    override fun spawn(location: PositionProperty) {
        namePlate.spawn(location)
    }

    override fun addPassenger(entity: FakeEntity) {
        namePlate.addPassenger(entity)
    }

    override fun removePassenger(entity: FakeEntity) {
        namePlate.removePassenger(entity)
    }

    override fun contains(entityId: Int): Boolean {
        return namePlate.contains(entityId)
    }

    override fun dispose() {
        namePlate.dispose()
    }
}