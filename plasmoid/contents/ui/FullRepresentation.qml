/*
 *  Copyright 2019 Davide Sandona' <sandona.davide@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtLocation 5.9
import QtPositioning 5.9
import QtQuick 2.2
import QtQuick.Controls as QtControls
import QtQuick.Layouts 2.1
import QtQuick.Window 2.1
import "js/index.js" as ExternalJS
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    readonly property bool layoutRow: plasmoid.configuration.layoutRow
    readonly property bool showHostname: plasmoid.configuration.showHostname
    readonly property int mapSize: plasmoid.configuration.mapSize
    readonly property int mapZoomLevel: plasmoid.configuration.mapZoomLevel
    readonly property bool useLabelThemeColor: plasmoid.configuration.useLabelThemeColor
    readonly property string labelColor: plasmoid.configuration.labelColor
    readonly property bool useLinkThemeColor: plasmoid.configuration.useLinkThemeColor
    readonly property string linkColor: plasmoid.configuration.linkColor
    // property string mapLink: "https://www.openstreetmap.org/#map=" + mapZoomLevel + "/" + latitude + "/" + longitude
    property string mapLink: "https://www.openstreetmap.org/?mlat=" + latitude + "&mlon=" + longitude + "#map=" + mapZoomLevel + "/" + latitude + "/" + longitude

    function addMarker(latitude, longitude) {
        debug_print("### addMarker init");
        var component = Qt.createComponent("Marker.qml");
        if (component.status != Component.Ready) {
            if (component.status == Component.Error)
                debug_print("### Error creating Marker:" + component.errorString());

            return ; // or maybe throw
        }
        // removing previous markers
        my_map.clearMapItems();
        var item = component.createObject(grid, {
            "coordinate": QtPositioning.coordinate(latitude, longitude)
        });
        my_map.addMapItem(item);
        debug_print("### Added Marker: lat=" + latitude + "; long=" + longitude);
    }

    Layout.preferredWidth: grid.width
    Layout.preferredHeight: grid.height

    GridLayout {
        id: grid

        rowSpacing: 10
        columnSpacing: 10
        flow: layoutRow ? GridLayout.LeftToRight : GridLayout.TopToBottom

        Item {
            // anchors.horizontalCenter: layoutRow ? undefined : parent.horizontalCenter

            width: mapSize
            height: width
            // // Fix issue https://github.com/Davide-sd/ip_address/issues/8
            Layout.alignment: layoutRow ? Qt.AlignLeft : Qt.AlignHCenter

            Plugin {
                // locales: ["it_IT","en_US"]
                // PluginParameter { name: "osm.useragent"; value: "My great Qt OSM application" }
                // PluginParameter { name: "osm.mapping.host"; value: "http://osm.tile.server.address/" }
                // PluginParameter { name: "osm.mapping.copyright"; value: "All mine" }
                // PluginParameter { name: "osm.routing.host"; value: "http://osrm.server.address/viaroute" }
                // PluginParameter { name: "osm.geocoding.host"; value: "http://geocoding.server.address" }

                id: mapPlugin

                name: "osm" // "mapboxgl", "esri", ...
            }

            Map {
                id: my_map

                anchors.fill: parent
                plugin: mapPlugin
                center: {
                    if (jsonData !== undefined) {
                        addMarker(latitude, longitude);
                        return QtPositioning.coordinate(latitude, longitude);
                    }
                    addMarker(41.8902, 12.4922);
                    return QtPositioning.coordinate(41.8902, 12.4922); // Rome
                }
                zoomLevel: mapZoomLevel
            }

        }

        GridLayout {
            id: labelsContainer

            flow: GridLayout.LeftToRight
            columns: 2
            Layout.minimumWidth: 600
            Layout.maximumWidth: 600
            Layout.preferredWidth: 600

            QtControls.Label {
                text: i18n("IP address:")
                color: useLabelThemeColor ? Kirigami.Theme.textColor : labelColor
            }

            LabelDelegate {
                text: jsonData !== undefined && jsonData.ip ? jsonData.ip : "N/A"
            }

            QtControls.Label {
                text: i18n("Country:")
                color: useLabelThemeColor ? Kirigami.Theme.textColor : labelColor
            }

            LabelDelegate {
                text: jsonData !== undefined && jsonData.country ? jsonData.country : "N/A"
            }

            QtControls.Label {
                text: i18n("Region:")
                color: useLabelThemeColor ? Kirigami.Theme.textColor : labelColor
            }

            LabelDelegate {
                text: jsonData !== undefined && jsonData.region ? jsonData.region : "N/A"
            }

            QtControls.Label {
                text: i18n("Postal Code:")
                color: useLabelThemeColor ? Kirigami.Theme.textColor : labelColor
            }

            LabelDelegate {
                text: jsonData !== undefined && jsonData.postal ? jsonData.postal : "N/A"
            }

            QtControls.Label {
                text: i18n("City:")
                color: useLabelThemeColor ? Kirigami.Theme.textColor : labelColor
            }

            LabelDelegate {
                text: jsonData !== undefined && jsonData.city ? jsonData.city : "N/A"
            }

            QtControls.Label {
                text: i18n("Coordinates:")
                color: useLabelThemeColor ? Kirigami.Theme.textColor : labelColor
            }

            LabelDelegate {
                text: jsonData !== undefined && jsonData.loc ? jsonData.loc : "N/A"
            }

            QtControls.Label {
                text: i18n("Hostname:")
                color: useLabelThemeColor ? Kirigami.Theme.textColor : labelColor
                visible: showHostname
            }

            LabelDelegate {
                text: jsonData !== undefined && jsonData.hostname ? jsonData.hostname : "N/A"
                visible: showHostname
            }

            QtControls.Label {
                Layout.columnSpan: 2
                // Fix issue https://github.com/Davide-sd/ip_address/issues/8
                Layout.alignment: Qt.AlignHCenter
                // anchors.horizontalCenter: parent.horizontalCenter
                color: useLinkThemeColor ? Kirigami.Theme.highlightColor : linkColor
                font.bold: true
                wrapMode: Text.Wrap
                text: jsonData !== undefined ? i18n("Open map in the browser") : "N/A"
                visible: jsonData !== undefined

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: false
                    onClicked: Qt.openUrlExternally(mapLink)
                }

            }

            QtControls.Button {
                // abortTooLongConnection()

                Layout.columnSpan: 2
                // Fix issue https://github.com/Davide-sd/ip_address/issues/8
                Layout.alignment: Qt.AlignHCenter
                // anchors.horizontalCenter: parent.horizontalCenter
                Layout.preferredWidth: parent.width
                text: i18n("Update")
                onClicked: {
                    debug_print("### [Update onClicked]");
                    root.reloadData();
                }
            }

        }

    }

}
