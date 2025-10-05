package com.typewritermc.basic.entries.static.factspreset.entries

import com.typewritermc.basic.entries.static.factspreset.*
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.around
import com.typewritermc.core.utils.formatted
import com.typewritermc.core.utils.loopingDistance
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.ConfirmationKeyHandler
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.dialogue.confirmationKey
import com.typewritermc.engine.paper.facts.FactsModifier
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.interaction.startBlockingMessages
import com.typewritermc.engine.paper.interaction.stopBlockingMessages
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.utils.toTicks
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.JoinConfiguration
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerItemHeldEvent
import kotlin.math.min
import kotlin.time.Duration.Companion.milliseconds


private val optionFormat: String by snippet(
    "facts.preset.format", """
			|<gray><st>${" ".repeat(60)}</st>
			|<white> Select one preset to apply:
			|
			|<options>
			|<#5d6c78>[ <grey><white>Scroll</white> to change preset and press<white> <confirmation_key> </white>to select <#5d6c78>]</#5d6c78>
			|<gray><st>${" ".repeat(60)}</st>
		""".trimMargin()
)

private val multipleOptionFormat: String by snippet(
    "facts.preset.format.multiple", """
			|<gray><st>${" ".repeat(60)}</st>
			|<white> Select multiple presets to apply:
			|
			|<options>
			|<#5d6c78>[ <grey><white>Scroll</white> to navigate, <white><confirmation_key></white> to toggle selection <#5d6c78>]
			|<#5d6c78>[ <grey>Double-press <white><confirmation_key></white> to finish and apply selected presets <#5d6c78>]
			|<gray><st>${" ".repeat(60)}</st>
		""".trimMargin()
)

private val upPrefix: String by snippet("facts.preset.prefix.up", "<white> ↑")
private val downPrefix: String by snippet("facts.preset.prefix.down", "<white> ↓")
private val unselectedPrefix: String by snippet("facts.preset.prefix.unselected", "  ")
private val currentPrefix: String by snippet("facts.preset.prefix.current", "<#78ff85>>>")
private val currentSelectedPrefix: String by snippet("facts.preset.prefix.current.selected", "<#78ff85>✓>")
private val selectedOnlyPrefix: String by snippet("facts.preset.prefix.selected.only", "<#78ff85>✓ ")

private val selectedOption: String by snippet(
    "facts.preset.selected",
    " <prefix> <#5d6c78>[ <#78ff85><option_text> <#5d6c78>]\n"
)
private val unselectedOption: String by snippet(
    "facts.preset.unselected",
    " <prefix> <#5d6c78>[ <grey><option_text> <#5d6c78>]\n"
)
private val currentOption: String by snippet(
    "facts.preset.current",
    " <prefix> <#5d6c78>[ <white><option_text> <#5d6c78>]\n"
)
private val currentSelectedOption: String by snippet(
    "facts.preset.current.selected",
    " <prefix> <#78ff85>[ <white><option_text> <#78ff85>]\n"
)

val DOUBLE_TAP_DELAY = 250.milliseconds

@Entry(
    "option_facts_preset",
    "Allows you to select the one/multiple of the children to be applied",
    Colors.BLUE,
    "f7:arrow-branch",
)
class OptionFactsPresetEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<FactsPresetEntry>> = emptyList(),
    override val presets: List<FactPreset> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val multiple: Boolean = false,
) : FactsPresetEntry {
    override fun applier(
        player: Player,
        modifier: FactsModifier,
        serializer: FactsPresetSerializer
    ): FactsPresetApplier<*> {
        return OptionFactsPresetApplier(player, this, modifier, serializer)
    }
}

class OptionFactsPresetApplier(
    player: Player,
    entry: OptionFactsPresetEntry,
    modifier: FactsModifier,
    serializer: FactsPresetSerializer
) :
    FactsPresetApplier<OptionFactsPresetEntry>(player, entry, modifier, serializer) {

    private var confirmationKeyHandler: ConfirmationKeyHandler? = null

    private var currentIndex = 0
    private val selectedIndices = mutableSetOf<Int>()

    private var lastConfirmation: Long = -1L

    private val current get() = entry.children.getOrNull(currentIndex)

    override val appliedChildren: List<Ref<FactsPresetEntry>>
        get() = entry.children.filterIndexed { index, _ -> selectedIndices.contains(index) }

    override fun init() {
        super.init()

        if (entry.children.isEmpty()) {
            state = FactsPresetApplierState.FINISHED
            return
        }

        val deserialization = serializer.pop()
        if (!deserialization.isNullOrBlank()) {
            selectedIndices.addAll(deserialization.trim().split(',').mapNotNull { it.toIntOrNull() })
            state = FactsPresetApplierState.FINISHED
            return
        }


        player.startBlockingMessages()

        confirmationKeyHandler = confirmationKey.handler(player) {
            handleConfirmation()
        }

        displayMessage()
    }

    private fun toggleSelection(index: Int) {
        if (selectedIndices.contains(index)) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.add(index)
        }
    }

    private fun handleConfirmation() {
        if (state != FactsPresetApplierState.RUNNING) return

        if (entry.multiple) {
            val now = System.currentTimeMillis()
            val diff = (now - lastConfirmation).milliseconds
            lastConfirmation = now
            if (diff < DOUBLE_TAP_DELAY) {
                // The previous toggle was actually not a toggle but a double tap, so we toggle it back
                // Unless this is the only thing, then we assume the player wants to just select this
                if (currentIndex !in selectedIndices) {
                    toggleSelection(currentIndex)
                } else if (selectedIndices.size > 1) {
                    toggleSelection(currentIndex)
                }
                state = FactsPresetApplierState.FINISHED
                return
            }

            toggleSelection(currentIndex)
            displayMessage()
        } else {
            // Single selection mode - finish immediately
            selectedIndices.clear()
            selectedIndices.add(currentIndex)
            state = FactsPresetApplierState.FINISHED
        }
    }

    @EventHandler
    private fun onPlayerItemHeld(event: PlayerItemHeldEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        val curSlot = event.previousSlot
        val newSlot = event.newSlot
        val dif = loopingDistance(curSlot, newSlot, 8)
        val index = currentIndex
        event.isCancelled = true
        var newIndex = (index + dif) % entry.children.size
        while (newIndex < 0) newIndex += entry.children.size
        currentIndex = newIndex
        displayMessage()
    }

    override fun tick(context: TickContext) {
        super.tick(context)
        if (state != FactsPresetApplierState.RUNNING) return

        if (context.playTime.toTicks() % 100 > 0) {
            // Only update periodically to avoid spamming the player
            return
        }

        displayMessage()
    }

    private fun displayMessage() {
        val formatText = if (entry.multiple) {
            multipleOptionFormat
        } else {
            optionFormat
        }

        val message = formatText.asMiniWithResolvers(
            Placeholder.component("options", formatOptions()),
        )

        val component = player.chatHistory.composeDarkMessage(message)
        player.sendMessage(component)
    }

    private fun formatOptions(): Component {
        val around = entry.children.around(currentIndex, 1, 2)

        val lines = mutableListOf<Component>()

        val maxOptions = min(4, around.size)

        for (i in 0 until maxOptions) {
            val option = around[i]
            val actualIndex = entry.children.indexOf(option)
            val isCurrent = current == option
            val isSelected = selectedIndices.contains(actualIndex)

            val prefix = when {
                isCurrent && isSelected -> currentSelectedPrefix
                isCurrent -> currentPrefix
                isSelected -> selectedOnlyPrefix
                i == 0 && currentIndex > 1 && entry.children.size > 4 -> upPrefix
                i == 3 && currentIndex < entry.children.size - 3 && entry.children.size > 4 -> downPrefix
                else -> unselectedPrefix
            }

            val format = when {
                isCurrent && isSelected -> currentSelectedOption
                isCurrent -> currentOption
                isSelected -> selectedOption
                else -> unselectedOption
            }

            lines += format.asMiniWithResolvers(
                Placeholder.parsed("prefix", prefix),
                Placeholder.parsed("option_text", option.get()?.name?.formatted ?: "<gray>Unknown")
            )
        }

        return Component.join(JoinConfiguration.noSeparators(), lines)
    }

    override fun dispose() {
        serializer.push(selectedIndices.joinToString(","))
        confirmationKeyHandler?.dispose()

        player.stopBlockingMessages()
        player.chatHistory.resendMessages(player)

        super.dispose()
    }
}