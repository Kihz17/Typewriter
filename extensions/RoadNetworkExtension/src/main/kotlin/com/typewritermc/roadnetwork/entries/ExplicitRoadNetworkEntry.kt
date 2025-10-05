package com.typewritermc.roadnetwork.entries

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.ContentEditor
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.hasData
import com.typewritermc.engine.paper.entry.entries.stringData
import com.typewritermc.roadnetwork.NetworkType
import com.typewritermc.roadnetwork.RoadNetwork
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.content.RoadNetworkContentMode

@Entry("explicit_road_network", "A road network with explicit node connections", Colors.ORANGE, "material-symbols:route")
/**
 * The `Explicit Road Network` is a definition of a road network where connections between nodes are explicitly defined.
 * Unlike the base road network that auto-connects nodes within range, this network only creates edges for explicitly defined connections.
 *
 * ## How could this be used?
 * To create precise road networks where you want full control over which nodes connect to each other.
 * Useful for complex road layouts where automatic connections would create unwanted paths.
 */
class ExplicitRoadNetworkEntry(
    override val id: String = "",
    override val name: String = "",
    @ContentEditor(RoadNetworkContentMode::class)
    override val artifactId: String = "",
) : RoadNetworkEntry {
    override suspend fun loadRoadNetwork(gson: Gson): RoadNetwork {
        if (!hasData()) return RoadNetwork(networkType = NetworkType.EXPLICIT_LINKS)
        val loadedNetwork = gson.fromJson<RoadNetwork>(stringData(), object : TypeToken<RoadNetwork>() {}.type)
        return loadedNetwork.copy(networkType = NetworkType.EXPLICIT_LINKS)
    }

    override suspend fun saveRoadNetwork(gson: Gson, network: RoadNetwork) {
        val networkToSave = network.copy(networkType = NetworkType.EXPLICIT_LINKS)
        stringData(gson.toJson(networkToSave))
    }
}