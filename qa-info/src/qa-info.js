const sketch = require('sketch')
// documentation: https://developer.sketchapp.com/reference/api/

export function onQAInfo(context) {
  console.log(`onQAInfo`);
  QAInfo(context, true)
}

export function onQAInfoNoPlugins(context) {
  console.log(`onQAInfoNoPlugins`);
  QAInfo(context, false)
}

function QAInfo(context, showPlugins) {
  var appMetadata = MSApplicationMetadata.metadata()
  var sysReport = "```\n"
  sysReport += `Build version: ${appMetadata.appVersion} (${appMetadata.build})\n`
  sysReport += `Build variant: ${appMetadata.variant}\n`
  sysReport += `OS version: ${NSProcessInfo.processInfo().operatingSystemVersionString()}\n`
  var cloudPlatform = SCKAPIEnvironment.current().name()
  var cloudEnabled = MSCloudAction.cloudEnabled()
  if (!cloudEnabled) {
    cloudPlatform = "(disabled)"
  }
  sysReport += "Cloud: " + cloudPlatform + "\n"
  sysReport += "```\n"

  if (showPlugins) {
    sysReport += "\n### Plugins:\n"

    var plugins = NSApplication.sharedApplication().delegate().pluginManager().plugins()

    var enabledPlugins = []
    var disabledPlugins = []

    for (var p in plugins) {
      var plugin = plugins.objectForKey(p)
      if (plugin.isEnabled()) {
        enabledPlugins.push(plugin)
      } else {
        disabledPlugins.push(plugin)
      }
    }

    enabledPlugins.forEach(plugin => {
      sysReport += metadataForPlugin(plugin)
    })
    disabledPlugins.forEach(plugin => {
      sysReport += metadataForPlugin(plugin)
    })
  }

  if (sysReport) {
    var pasteBoard = NSPasteboard.generalPasteboard()
    pasteBoard.clearContents()
    pasteBoard.writeObjects([sysReport])
    sketch.UI.message("Sketch app info copied to Clipboard")
  } else {
    sketch.UI.message("Uh, oh, something’s wrong here!")
  }
}
function websiteFromAppcastURL(url){
  if (url == null) {
    return url
  }
  var url = String(url)
  // https://raw.githubusercontent.com/BohemianCoding/unsplash-sketchplugin/master/.appcast.xml
  // https://raw.githubusercontent.com//master/.appcast.xml
  if ( url == "https://raw.githubusercontent.com//master/.appcast.xml" ) {
    return null
  } else {
    if (url.includes('githubusercontent')) {
      // Plugin is hosted on GitHub
      var user = url.split('/')[3]
      var project = url.split('/')[4]
      return `https://github.com/${user}/${project}`
    } else {
      return url
    }
  }
}

function metadataForPlugin(plugin){
  var returnString = `- ${(plugin.isEnabled() ? "🔘" : "⚪️")} ${plugin.name()} (${plugin.identifier()}) (v${plugin.version()})`
  var pluginURL = plugin.homepageURL() || websiteFromAppcastURL(plugin.appcastURL())
  if (pluginURL != null) {
    returnString += ` [Website](${pluginURL})`
  }
  returnString += "\n"
  return returnString
}