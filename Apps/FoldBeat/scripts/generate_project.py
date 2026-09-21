from pathlib import Path
import hashlib, plistlib
root=Path(__file__).resolve().parents[1]
objects={}
def add(key, isa, **fields):
    uid=hashlib.sha1(key.encode()).hexdigest()[:24].upper()
    objects[uid]={'isa':isa,**fields}
    return uid
sources=[]; refs=[]
for p in sorted((root/'Sources').glob('*.swift')):
    ref=add(p.name,'PBXFileReference',lastKnownFileType='sourcecode.swift',path=p.name,sourceTree='<group>')
    refs.append(ref); sources.append(add('build'+p.name,'PBXBuildFile',fileRef=ref))
group=add('sources','PBXGroup',children=refs,path='Sources',sourceTree='<group>')
product=add('product','PBXFileReference',explicitFileType='wrapper.application',path='FoldBeat.app',sourceTree='BUILT_PRODUCTS_DIR')
products=add('products','PBXGroup',children=[product],name='Products',sourceTree='<group>')
assets=add('assets','PBXFileReference',lastKnownFileType='folder.assetcatalog',path='Assets.xcassets',sourceTree='<group>')
assetbuild=add('assetbuild','PBXBuildFile',fileRef=assets)
main=add('main','PBXGroup',children=[group,products,assets],sourceTree='<group>')
sourcephase=add('sourcesphase','PBXSourcesBuildPhase',buildActionMask=2147483647,files=sources,runOnlyForDeploymentPostprocessing=0)
frameworks=add('frameworks','PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[],runOnlyForDeploymentPostprocessing=0)
resources=add('resources','PBXResourcesBuildPhase',buildActionMask=2147483647,files=[assetbuild],runOnlyForDeploymentPostprocessing=0)
base={'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'27.1','SWIFT_VERSION':'6.0','CLANG_ENABLE_MODULES':'YES','SWIFT_STRICT_CONCURRENCY':'complete','SWIFT_DEFAULT_ACTOR_ISOLATION':'MainActor'}
app={'ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','PRODUCT_BUNDLE_IDENTIFIER':'org.duodemos.foldbeat','PRODUCT_NAME':'$(TARGET_NAME)','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_KEY_CFBundleDisplayName':'折叠鼓机','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone':'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight','INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad':'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight','TARGETED_DEVICE_FAMILY':'1,2','CODE_SIGNING_ALLOWED':'NO','MARKETING_VERSION':'0.1.0','CURRENT_PROJECT_VERSION':'1','SWIFT_EMIT_LOC_STRINGS':'YES'}
def configs(prefix, settings):
    ids=[]
    for name in ['Debug','Release']:
        bs=dict(settings)
        bs['SWIFT_OPTIMIZATION_LEVEL']='-Onone' if name=='Debug' else '-O'
        if name=='Debug': bs['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='DEBUG'
        ids.append(add(prefix+name,'XCBuildConfiguration',name=name,buildSettings=bs))
    return add(prefix+'list','XCConfigurationList',buildConfigurations=ids,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
target=add('target','PBXNativeTarget',name='FoldBeat',productName='FoldBeat',productType='com.apple.product-type.application',productReference=product,buildConfigurationList=configs('app',app),buildPhases=[sourcephase,frameworks,resources],buildRules=[],dependencies=[])
project=add('project','PBXProject',attributes={'LastUpgradeCheck':'2710'},buildConfigurationList=configs('project',base),compatibilityVersion='Xcode 14.0',developmentRegion='zh-Hans',knownRegions=['zh-Hans','en','Base'],mainGroup=main,productRefGroup=products,projectDirPath='',projectRoot='',targets=[target])
out=root/'FoldBeat.xcodeproj'; out.mkdir(exist_ok=True)
(out/'project.pbxproj').write_bytes(plistlib.dumps({'archiveVersion':'1','classes':{},'objectVersion':'56','objects':objects,'rootObject':project}))
scheme=out/'xcshareddata/xcschemes'; scheme.mkdir(parents=True,exist_ok=True)
ref=f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="FoldBeat.app" BlueprintName="FoldBeat" ReferencedContainer="container:FoldBeat.xcodeproj"/>'
(scheme/'FoldBeat.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?><Scheme LastUpgradeVersion="2710" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''')
print(out)
