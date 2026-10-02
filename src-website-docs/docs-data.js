/* Source-led documentation content for the current Roblox/Luau implementation. */
(() => {
  const h = (value) => String(value).replace(/[&<>"']/g, (char) => ({"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#39;"})[char]);
  const route = (id, label) => `<a href="#/${id}">${label}</a>`;
  const scriptLink = (id, label) => route(`script/${id}`, label);
  const eventLink = (name, label = name, place = 'material-lab') => route(`events@${place === 'small-town' ? 'town' : 'lab'}-${name.toLowerCase()}`, `<code>${h(label)}</code>`);
  const pill = (label, color = '') => `<span class="pill ${color}">${h(label)}</span>`;
  const card = (id, kicker, title, description) => `<a class="doc-card" href="#/${id}"><span class="card-kicker">${h(kicker)}</span><strong>${h(title)} →</strong><p>${h(description)}</p></a>`;
  const callout = (kind, title, body) => `<aside class="callout ${kind}"><span class="callout-icon" aria-hidden="true">${kind === 'warning' ? '!' : kind === 'info' ? 'i' : '✓'}</span><p><strong>${title}</strong> ${body}</p></aside>`;
  const table = (heads, rows) => `<div class="data-table-wrap${heads.length >= 4 ? ' is-wide' : heads.length === 3 ? ' is-medium' : ''}"><table class="data-table"><thead><tr>${heads.map((head) => `<th scope="col">${head}</th>`).join('')}</tr></thead><tbody>${rows.map((row) => `<tr>${row.map((cell) => `<td>${cell}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
  const highlight = (source) => {
    const pattern = /(--[^\n]*|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\b(?:local|function|return|if|then|else|elseif|end|for|in|do|and|or|not|true|false|nil|continue)\b|\b\d+(?:\.\d+)?\b)/g;
    let output = '';
    let previous = 0;
    for (const match of source.matchAll(pattern)) {
      output += h(source.slice(previous, match.index));
      const token = match[0];
      const type = token.startsWith('--') ? 'comment' : /^['"]/.test(token) ? 'string' : /^\d/.test(token) ? 'number' : 'keyword';
      output += `<span class="tok-${type}">${h(token)}</span>`;
      previous = match.index + token.length;
    }
    return output + h(source.slice(previous));
  };
  const code = (source, caption = 'From the Luau source') => `<div class="code-block"><div class="code-caption"><span>${h(caption)}</span><span class="language">Luau</span></div><pre><code>${highlight(source.trim())}</code></pre></div>`;
  const diagram = (rows, caption) => `<div class="diagram" role="img" aria-label="${h(caption)}">${rows.map((nodes) => `<div class="diagram-row">${nodes.map((node, index) => `${index ? '<span class="diagram-arrow" aria-hidden="true">→</span>' : ''}<div class="diagram-node ${node.tone || ''}"><strong>${h(node.title)}</strong><span>${h(node.note)}</span></div>`).join('')}</div>`).join('')}<div class="diagram-caption">${h(caption)}</div></div>`;

  const script = (place, location, summary, options = {}) => {
    const filename = location.split('/').pop();
    const stem = filename.replace(/\.luau$/, '');
    const id = `${place === 'material-lab' ? 'lab' : 'town'}-${stem.replace(/([A-Z]+)([A-Z][a-z])/g, '$1-$2').replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase()}`;
    const runtime = location.startsWith('ReplicatedStorage/') ? 'Shared' : location.startsWith('ServerScriptService/') ? 'Server' : 'Client';
    const kind = runtime === 'Shared' ? 'ModuleScript' : runtime === 'Server' ? 'Script' : 'LocalScript';
    return { id, name: stem, path: `src/Places/${place}/${location}`, place, runtime, kind, summary, functions: [], state: '', services: [], objects: [], events: [], modules: [], related: [], terms: [], ...options };
  };

  const scripts = [
    script('material-lab', 'ReplicatedStorage/FrequencyData.luau', 'Shared list of four frequency options, a band-name lookup table, and the default 3500 MHz option.', {
      state: 'Options stores display name, band, divisor, and maxDistance; ByBand indexes the same entries; Default points to 3500 MHz.',
      functions: ['No named functions; a loop builds the ByBand lookup from Options.'],
      services: ['ReplicatedStorage (container)'], objects: ['FrequencyData module'],
      modules: ['Required by PlayerSignalHandler and RoomOneDashboard.'],
      related: ['simulation/frequency', 'configuration'], terms: ['700 MHz', '1800 MHz', '2100 MHz', '3500 MHz']
    }),
    script('material-lab', 'ServerScriptService/RoomDetection.luau', 'Samples room volumes and nearby antenna parts, then publishes player room and antenna attributes.', {
      functions: ['isPointInsideBox — tests a position in a rotated zone part.', 'getClosestAntenna — selects a configured antenna within a 25 stud radius.', 'setupPlayer — initializes room and antenna attributes.'],
      state: 'CHECK_INTERVAL is 0.1 seconds; playerStates caches each player’s previous room flags so changes are published on transitions.',
      services: ['Players', 'RunService'], objects: ['RoomOneZone', 'RoomTwoZone', 'OmniPart', 'DirectionalPart', 'MainPart'],
      events: [['Listens', 'Heartbeat', 'periodic room and antenna checks'], ['Writes', 'Player attributes', 'InRoomOne, InRoomTwo, AntennaType, BeamWidth, TiltAngle, Azimuth, Elevation']],
      related: ['architecture', 'experience/material-lab', 'interface'], terms: ['zone', 'antenna detection']
    }),
    script('material-lab', 'ServerScriptService/PlayerShrinkHandler.luau', 'Shrinks a character and walk speed in room one, then restores cached original values after leaving.', {
      functions: ['saveOriginalValues — caches scale and speed.', 'shrinkPlayer — applies the 0.2 multiplier.', 'resetPlayer — restores values and clears the cache.', 'updatePlayerSize — responds to InRoomOne.'],
      state: 'SHRINK_MULTIPLIER = 0.2; RESET_UPWARD_OFFSET = 2.5; tables cache each player’s original scales, walk speed, and attribute connection.',
      services: ['Players'], objects: ['Humanoid scale values', 'HumanoidRootPart', 'InRoomOne attribute'],
      events: [['Listens', 'AttributeChanged', 'InRoomOne, plus character and player lifecycle']],
      related: ['experience/material-lab', 'architecture']
    }),
    script('material-lab', 'ServerScriptService/PlaceMaterialHandler.luau', 'Validates material placement requests and clones allowed blocks into the room-one material folder.', {
      functions: ['snap and snapY — align submitted positions to the 2 stud grid.', 'isPlayerOnHeatmap — checks room and player position.', 'isPositionOnHeatmap — checks the requested position.'],
      state: 'ALLOWED_MATERIALS permits Concrete, Metal, and Wood; GRID_SIZE = 2; MAX_DISTANCE = 50 studs; bounds constrain X and Z.',
      services: ['ReplicatedStorage', 'Players'], objects: ['PlaceableMaterials', 'LevelOneMaterials', 'InRoomOne attribute'],
      events: [['Receives', 'PlaceItemEvent', 'materialName and CFrame']], related: ['simulation/materials', 'experience/material-lab'], terms: ['grid snapping', 'placement']
    }),
    script('material-lab', 'ServerScriptService/PlayerSignalHandler.luau', 'Computes per-player source distance, first material hit, RSRP-like value, and SINR display value.', {
      functions: ['findClosestSignalSource — selects the nearest source.', 'getMaterialAttenuation — raycasts through LevelOneMaterials.', 'calculateRSRP — applies frequency divisor, material loss, and smoothed noise.', 'calculateSINR — compares serving power with other sources and a noise floor.', 'updatePlayerSignal — publishes player attributes.'],
      state: 'CHECK_INTERVAL = 0.1 seconds; NOISE_FLOOR_DBM = -100; playerNoise caches the smoothed random offset.',
      services: ['Players', 'RunService', 'ReplicatedStorage'], objects: ['SignalSourcesFolder', 'LevelOneMaterials', 'player signal attributes'],
      modules: ['FrequencyData'], events: [['Receives', 'FrequencyChangedEvent', 'frequencyBand; validates it against FrequencyData.ByBand'], ['Writes', 'Player attributes', 'FrequencyBand, RSRP, SINR, Material, Attenuation, TowerDistance, ClosestSignalSource']],
      related: ['simulation/signal', 'simulation/frequency', 'simulation/materials'], terms: ['RSRP', 'SINR', 'interference', 'attenuation']
    }),
    script('material-lab', 'ServerScriptService/HeatmapHandler.luau', 'Creates the room-one heatmap grid and incrementally colors tiles for RSRP or SINR.', {
      functions: ['valueToColour — maps a normalized value through red, yellow, and green.', 'getPreferredMaterial — chooses one intersecting placed material by priority.', 'calculateRSRPDbm — maps distance to the configured range and applies a decaying material shadow.', 'updateRSRP and updateSINR — refresh one random tile each call.'],
      state: 'ROWS = 24, COLUMNS = 30, SPACING = 2; 30 random tiles update per Heartbeat; maxDistance starts at 30 and is changed by FrequencyChangedEvent.',
      services: ['RunService', 'ReplicatedStorage', 'Workspace'], objects: ['LevelOne.HeatmapTile', 'LevelOneMaterials', 'SignalSourcesFolder', 'HeatmapGrid'],
      events: [['Receives', 'FrequencyChangedEvent', 'frequencyBand and newMaxDistance; this handler uses the distance argument'], ['Receives', 'ToggleHeatmapEvent', 'RSRP or SINR mode']],
      related: ['simulation/heatmap', 'simulation/signal', 'configuration'], terms: ['heatmap', 'RSRP', 'SINR', 'shadow falloff']
    }),
    script('material-lab', 'ServerScriptService/AntennaBeamSimulation.luau', 'Builds colored point visualizations of directional, narrow, and omnidirectional antenna patterns.', {
      functions: ['numberToColor — interpolates over a color palette.', 'createDirectionalBeam — creates and updates a sampled directional visualization.', 'pointStrength (nested) — maps angular offset and configured gain to 0–1 visual strength.'],
      state: 'Beam settings include radius, sample density, horizontal and vertical beamwidth, front-to-back ratio, and orientation.',
      services: ['Workspace', 'ReplicatedStorage'], objects: ['DirectionalPart', 'MainPart', 'beam visualization folders'],
      events: [['Receives', 'UpdateAntennaEvent', 'antennaType, elevation, azimuth; updates directional or narrow beam']],
      related: ['simulation/antennas', 'experience/material-lab'], terms: ['beamforming', 'azimuth', 'elevation', 'gain']
    }),
    script('material-lab', 'ServerScriptService/NPCSpawner.luau', 'Maintains the material-lab NPC count and starts simple room-one wandering behavior.', {
      functions: ['getRandomPositionInRoomOne — samples inside a padded zone.', 'spawnNPC — clones, colors, and starts movement.', 'removeNPC and getNPCCount — adjust and report the folder count.'],
      state: 'MAX_NPCS = 50; collision group NPC prevents NPC-to-NPC collisions; the script chooses shirt and pants colors.',
      services: ['Players', 'ServerStorage', 'ReplicatedStorage', 'Workspace', 'PhysicsService'], objects: ['NPCTemplate', 'NPCs', 'RoomOneZone'],
      events: [['Receives / sends', 'NPCSpawnEvent', 'setCount/getCount request and numeric count response']], related: ['experience/material-lab', 'events'], terms: ['NPC count']
    }),
    script('material-lab', 'StarterPlayer/StarterPlayerScripts/RoomCameraZoom.luau', 'Tweens the local player’s camera zoom as room-one presence changes.', {
      functions: ['tweenCameraZoom — animates zoom limits and optionally restores them.', 'updateCameraZoom — chooses close or normal target based on InRoomOne.'],
      state: 'Saved initial camera limits, SHRUNK_ZOOM = 2.5, NORMAL_ZOOM = 12, and the active Tween.',
      services: ['Players', 'TweenService'], objects: ['LocalPlayer', 'InRoomOne attribute'],
      events: [['Listens', 'AttributeChanged', 'InRoomOne']], related: ['experience/material-lab', 'interface']
    }),
    script('material-lab', 'StarterPlayer/StarterPlayerScripts/RoomOneMaterialPlacer.luau', 'Displays a local material preview, calculates grid placement from the cursor, and requests server placement.', {
      functions: ['createPreview and selectMaterial — switch the translucent local block.', 'getPlacementCFrame — raycasts and aligns to a tile or existing block face.', 'placeItem — sends a selected material and transform.'],
      state: 'selectedMaterialName, rotationY, previewPart, currentPlacementCFrame, and placementEnabled hold local tool state; X/Z bounds match the placement area.',
      services: ['Players', 'ReplicatedStorage', 'RunService', 'UserInputService'], objects: ['PlaceableMaterials', 'HeatmapGrid', 'LevelOneMaterials'],
      events: [['Sends', 'PlaceItemEvent', 'selectedMaterialName and currentPlacementCFrame'], ['Listens', 'RenderStepped / InputBegan', 'moves preview and handles 1–3, R, M, and click']],
      related: ['simulation/materials', 'experience/material-lab'], terms: ['preview', 'grid snapping']
    }),
    script('material-lab', 'StarterPlayer/StarterPlayerScripts/RayVisual.luau', 'Draws a client-local neon part between the player and SignalSource while room one is active.', {
      functions: ['setupCharacter — caches the character root as the ray origin.'],
      state: 'visualPart is resized and centered every RenderStepped update; it is hidden outside room one.',
      services: ['Players', 'RunService'], objects: ['SignalSource', 'HumanoidRootPart', 'InRoomOne attribute'],
      events: [['Listens', 'CharacterAdded / RenderStepped', 'refreshes the root reference and visual length']], related: ['experience/material-lab', 'interface']
    }),
    script('material-lab', 'StarterPlayer/StarterCharacterScripts/git-track.luau', 'Temporary placeholder that prints a reminder when it runs.', {
      state: 'No simulation state or configuration.', objects: ['StarterCharacterScripts'], related: ['code-reference'], terms: ['placeholder']
    }),
    script('material-lab', 'StarterGui/DashboardGui/RoomOneDashboard.luau', 'Shows room-one signal, quality, tower, material experiment, frequency, and NPC information.', {
      functions: ['updateDashboardVisibility — reacts to room flags.', 'sendFrequencyToServer — sends a changed slider selection.', 'updateUI — refreshes metrics, badges, capacity, and material insight text.'],
      state: 'frequencyOptions, npcCount, baseSignalValue, slider index, and tween state drive the dashboard.',
      services: ['TweenService', 'Players', 'RunService', 'ReplicatedStorage'], objects: ['DashboardGui.Room1Frame', 'player signal attributes'], modules: ['FrequencyData (required by the script)'],
      events: [['Sends', 'FrequencyChangedEvent', 'frequency band and maxDistance'], ['Receives / sends', 'NPCSpawnEvent', 'count updates / initial getCount']],
      related: ['interface', 'simulation/frequency', 'simulation/signal'], terms: ['RSRP', 'SINR', 'frequency slider']
    }),
    script('material-lab', 'StarterGui/DashboardGui/RoomTwoDashboard.luau', 'Displays room-two antenna labels and a local nearest-antenna signal estimate.', {
      functions: ['getAntennaSignal — computes a bounded distance-based display value.', 'updateVisibility — shows the panel only in room two.', 'updateRoom2 — paints labels, bars, badges, and insight text.'],
      state: 'A five-bar display and signal/status labels are refreshed on RenderStepped.',
      services: ['Players', 'RunService'], objects: ['DashboardGui.Room2Frame', 'OmniPart', 'DirectionalPart', 'MainPart', 'player antenna attributes'],
      events: [['Listens', 'AttributeChanged / RenderStepped', 'room visibility and live display refresh']], related: ['interface', 'simulation/antennas'], terms: ['antenna', 'room two']
    }),
    script('material-lab', 'StarterGui/DashboardGui/SliderControls.luau', 'Builds azimuth and elevation sliders and sends the selected antenna orientation.', {
      functions: ['createSlider — constructs a control and holds its value.', 'sendAntennaUpdate — sends permitted antenna settings.', 'updateVisibility — chooses controls for Directional or NarrowBeam.'],
      state: 'activeSlider, isDragging, azimuthSlider, and elevationSlider track client control state.',
      services: ['Players', 'UserInputService', 'ReplicatedStorage'], objects: ['AntennaControlGui', 'ClosestSignalSource and InRoomTwo attributes'],
      events: [['Sends', 'UpdateAntennaEvent', 'antennaType, elevation, azimuth']], related: ['interface', 'simulation/antennas'], terms: ['beamforming', 'slider']
    }),
    script('material-lab', 'StarterGui/DashboardGui/HeatmapToggle.luau', 'Switches the requested heatmap display between RSRP and SINR.', {
      state: 'showingSINR tracks the local button label and requested mode.', services: ['Players', 'ReplicatedStorage'], objects: ['DashboardGui.Room1Frame.HeatmapButton'],
      events: [['Sends', 'ToggleHeatmapEvent', 'RSRP or SINR string']], related: ['simulation/heatmap', 'interface'], terms: ['RSRP', 'SINR']
    }),
    script('material-lab', 'StarterGui/DashboardGui/PopUpScript.luau', 'Displays antenna settings and type-specific explanatory text in the room-two popup.', {
      functions: ['updatePopUp — reads antenna attributes and refreshes labels and guidance.'],
      state: 'The popup starts hidden and toggles from OpenPopUpButton and CloseButton.', services: ['Players'], objects: ['DashboardGui.PopUpFrame', 'DashboardGui.Room2Frame', 'antenna attributes'],
      events: [['Listens', 'AttributeChanged / button clicks', 'antenna values and popup visibility']], related: ['interface', 'simulation/antennas']
    }),
    script('material-lab', 'StarterGui/NPCControlScript.luau', 'Creates a room-one NPC count slider and synchronizes its count with the server.', {
      functions: ['updateSlider — clamps and displays a count.', 'sendCountToServer — sends a changed target count.'],
      state: 'MAX_NPCS = 50; currentCount, lastSentCount, and isDragging hold local slider state.', services: ['Players', 'ReplicatedStorage', 'UserInputService'], objects: ['NPCControlGui', 'InRoomOne attribute'],
      events: [['Sends / receives', 'NPCSpawnEvent', 'setCount/getCount and numeric count response']], related: ['interface', 'experience/material-lab']
    }),

    script('small-town', 'ServerScriptService/StartGame.luau', 'Starts a session from a world prompt and resets placed antennas, NPCs, speed, and position on request.', {
      functions: ['Prompt handler — records the active player and fires StartGame.', 'ResetGame handler — checks active player, clears owned placed antennas and NPCs, and sends completion.'],
      state: 'activePlayer tracks the current session owner.', services: ['Players', 'ReplicatedStorage'], objects: ['StartButton.ProximityPrompt', 'PlacedAntennas', 'NPCs', 'SpawnLocation'],
      events: [['Sends', 'StartGame', 'to the player who triggered the prompt'], ['Receives / sends', 'ResetGame', 'client reset request / completion notification'], ['Sends', 'NPCSpawnEvent', 'count 0 after reset']],
      related: ['experience/small-town', 'events']
    }),
    script('small-town', 'ServerScriptService/AntennaServer.luau', 'Validates placement and deletion requests, positions antenna models, and stores ownership.', {
      functions: ['computeBaseCenter — finds the model base so rotated placement keeps it on target.', 'PlaceAntenna handler — validates type, Vector3 position, and rotation.', 'DeleteAntenna handler — checks the Owner tag.'],
      state: 'validAntennas and antennaDisplayNames map permitted templates; antennaOwners also tracks placed model ownership.',
      services: ['ReplicatedStorage', 'Workspace'], objects: ['AntennaModels', 'PlacedAntennas', 'Owner StringValue'],
      events: [['Receives', 'PlaceAntenna', 'antennaName, position, rotationAngle'], ['Receives', 'DeleteAntenna', 'antennaInstanceName']],
      related: ['simulation/antennas', 'experience/small-town'], terms: ['ownership', 'placement']
    }),
    script('small-town', 'ServerScriptService/AntennaSignalManager.luau', 'Selects a fixed tower or placed antenna for each player and publishes its estimated signal and load.', {
      functions: ['getSignalOriginPos — selects SignalOrigin or pivot.', 'getOuterRadius and getTowerOuterRadius — combine type range and frequency divisor.', 'Heartbeat handler — chooses an in-range antenna when possible, applies distance and NPC load penalties.'],
      state: 'Frequency divisors and antenna/tower type radius tables are local to this script; update cadence is 0.2 seconds.',
      services: ['Players', 'RunService', 'Workspace'], objects: ['CellTowers', 'PlacedAntennas', 'NPCConnections attribute'],
      events: [['Writes', 'Player attributes', 'PlacedAntennaName, PlacedAntennaSignal, PlacedAntennaNPCLoad, PlacedAntennaInRange']],
      related: ['simulation/signal', 'simulation/antennas', 'experience/small-town'], terms: ['NPC load', 'coverage']
    }),
    script('small-town', 'ServerScriptService/RayMaterialDetection.luau', 'Raycasts toward the nearest fixed tower through town attenuation zones and publishes the detected zone.', {
      functions: ['getClosestTower — chooses the nearest CellTowers model.', 'updatePlayerMaterial — raycasts to SignalOrigin and writes material, attenuation, and tower attributes.'],
      state: 'CHECK_INTERVAL = 0.1 seconds; a raycast filter includes TownAttenuationZones.', services: ['Players', 'RunService', 'Workspace'],
      objects: ['CellTowers', 'TownAttenuationZones', 'SignalOrigin'], events: [['Writes', 'Player attributes', 'Material, Attenuation, ConnectedTower, ConnectedTowerType']],
      related: ['simulation/materials', 'simulation/signal', 'experience/small-town']
    }),
    script('small-town', 'ServerScriptService/TowerSignalManager.luau', 'Computes a fixed-tower distance and attenuation signal estimate for player attributes.', {
      functions: ['getClosestTower — reads an initial cache of CellTowers with SignalOrigin.', 'updatePlayerSignal — applies frequency divisor, tower max-power offset, attenuation, and small noise.'],
      state: 'Local tower type range and frequency tables; DEFAULT_FREQUENCY = 2100 MHz; update cadence is 0.2 seconds.',
      services: ['Players', 'RunService', 'Workspace'], objects: ['CellTowers', 'SignalOrigin', 'player material attributes'],
      events: [['Writes', 'Player attributes', 'ConnectedTower, ConnectedTowerType, RSRP, SignalBars, TowerDistance, FrequencyBand']],
      related: ['simulation/signal', 'simulation/frequency', 'experience/small-town'], terms: ['RSRP', 'tower']
    }),
    script('small-town', 'ServerScriptService/WallDetection.luau', 'Draws a server-owned ray part from each player to Source and checks overlapping parts for material attenuation.', {
      functions: ['updateRay — sizes the visual part and calls GetPartsInPart to inspect overlaps.'],
      state: 'One named RayVisual part is used per player and destroyed on PlayerRemoving.', services: ['Players', 'Workspace'],
      objects: ['Source', 'Cell Tower', 'player RayVisual part'], events: [['Writes', 'Player attributes', 'Material and Attenuation']],
      related: ['simulation/materials', 'experience/small-town']
    }),
    script('small-town', 'ServerScriptService/LEDManager.luau', 'Toggles marked LED SelectionBoxes using Lighting.TimeOfDay.', {
      functions: ['updateLEDs — shows boxes from 18:00 to 06:00.'],
      state: 'ledBoxes holds SelectionBoxes found at startup by IsLED attribute or LED-named parent.', services: ['Lighting', 'Workspace'],
      objects: ['SelectionBox', 'IsLED attribute'], events: [['Listens', 'Lighting property changes', 'TimeOfDay and Changed']],
      related: ['experience/small-town'], terms: ['environment', 'lighting']
    }),
    script('small-town', 'ServerScriptService/NPCSpawner.luau', 'Spawns wandering NPCs and tracks their nearest tower or placed antenna as a connection count.', {
      functions: ['getRandomSpawnPosition — samples ground positions with raycasts and spacing checks.', 'findNearestTower and reevaluateNPCConnections — assign nearest tower by SignalOrigin.', 'spawnNPC, removeNPC, getNPCCount — maintain population and load attributes.'],
      state: 'MAX_NPCS = 50, SPAWN_RADIUS = 40, MIN_SPAWN_DISTANCE = 5; towerConnections holds counts by model name.',
      services: ['Players', 'ServerStorage', 'ReplicatedStorage', 'Workspace', 'PhysicsService'], objects: ['NPCTemplate', 'NPCs', 'CellTowers', 'PlacedAntennas'],
      events: [['Receives / sends', 'NPCSpawnEvent', 'add/remove/setCount/getCount requests and numeric count response'], ['Receives', 'ResetGame', 'clears NPC connection tracking']],
      related: ['experience/small-town', 'simulation/antennas', 'simulation/signal'], terms: ['NPC load']
    }),
    script('small-town', 'StarterPlayer/StarterPlayerScripts/Antennaplacer.luau', 'Creates the placement GUI, manages antenna preview and budget, and submits place/delete/reset requests.', {
      functions: ['computeBaseCenter and createPreview — align the model preview.', 'getMousePosition and rotatePreview — update cursor placement and orientation.', 'showResultsPopup and createGUI — manage the activity UI.'],
      state: 'INITIAL_BUDGET = 1000; antennaOptions maps four model names to costs; selected antenna, preview, angle, and current budget are local.',
      services: ['Players', 'ReplicatedStorage', 'RunService', 'UserInputService'], objects: ['AntennaModels', 'PlacedAntennas', 'player GUI', 'CoverageScore attribute'],
      events: [['Sends', 'PlaceAntenna', 'model name, Vector3 position, rotation'], ['Sends', 'DeleteAntenna', 'model instance name'], ['Sends / receives', 'ResetGame', 'reset request and completion'], ['Receives', 'StartGame', 'starts placement activity']],
      related: ['experience/small-town', 'simulation/antennas', 'interface'], terms: ['budget', 'coverage score']
    }),
    script('small-town', 'StarterPlayer/StarterPlayerScripts/CellTowerVisualizer.luau', 'Draws concentric signal-range spheres and estimates map coverage by grid sampling.', {
      functions: ['getTowerType and getMaxDistance — resolve model types and range.', 'collectCoverageSpheres and calculateCoverage — sample a 50 × 50 map grid.', 'updateTowerVisuals and createToggleUI — maintain local spheres and coverage UI.'],
      state: 'MAP_BOUNDS sets a rectangular sampling area; frequencyData changes sphere radii; isVisible controls drawn spheres.',
      services: ['Players', 'RunService', 'Workspace'], objects: ['CellTowers', 'PlacedAntennas', 'AllSignalVisuals', 'CoverageScore attribute'],
      events: [['Writes', 'Player attribute', 'CoverageScore for the results UI'], ['Listens', 'UI click / timer', 'toggles spheres and refreshes the estimate']],
      related: ['simulation/antennas', 'experience/small-town', 'interface'], terms: ['coverage', '50x50']
    }),
    script('small-town', 'StarterPlayer/StarterPlayerScripts/ThirdPersonCamera.luau', 'Restores third-person camera control after StartGame and adjusts zoom from wheel and keyboard input.', {
      functions: ['setZoom — clamps and applies a target zoom, then restores allowed limits.'],
      state: 'defaultDistance, minDistance, maxDistance, and ZOOM_STEP control local camera movement.',
      services: ['Players', 'ReplicatedStorage', 'UserInputService'], objects: ['CurrentCamera', 'ZoomInfoGui'],
      events: [['Receives', 'StartGame', 'restores custom camera control'], ['Listens', 'InputChanged / InputBegan', 'mouse wheel and keyboard zoom']],
      related: ['experience/small-town', 'interface']
    }),
    script('small-town', 'StarterGui/SpeedControlScript.luau', 'Creates a walk-speed slider and adjusts the local character’s Humanoid speed.', {
      functions: ['updateSlider — maps speed to slider position.', 'applySpeed — sets Humanoid.WalkSpeed.', 'setBaseSpeed — combines UI and character update.'],
      state: 'MIN_SPEED = 16, MAX_SPEED = 130, SPRINT_MULTIPLIER = 3; drag and hover flags control local UI behavior.',
      services: ['Players', 'UserInputService'], objects: ['SpeedControlGui', 'Humanoid'],
      events: [['Receives', 'StartGame', 'sets speed to 130'], ['Receives', 'ResetGame', 'resets to MIN_SPEED']],
      related: ['experience/small-town', 'interface']
    }),
    script('small-town', 'StarterGui/DashboardGui/TownDashboardScript.luau', 'Renders selected antenna signal, range status, NPC load, and capacity graphics.', {
      functions: ['findUIElements — locates the dashboard cards.', 'updateSignalBars and clearSignalBars — map RSRP-like value to five bars.'],
      state: 'npcCount stores received count; bars and UI references cache dashboard widgets.',
      services: ['Players', 'RunService', 'ReplicatedStorage'], objects: ['DashboardGui.TownFrame', 'PlacedAntenna* player attributes'],
      events: [['Receives / sends', 'NPCSpawnEvent', 'count updates / initial getCount'], ['Listens', 'RenderStepped', 'refreshes dashboard display']],
      related: ['interface', 'experience/small-town', 'simulation/signal']
    }),
    script('small-town', 'StarterGui/NPCControlScript.luau', 'Creates the small-town NPC count slider and synchronizes it with the server.', {
      functions: ['updateSlider — clamps and renders the count.', 'sendCountToServer — sends changed target count.', 'updatePlacementState — sets CanPlaceAntenna while hovering or dragging.'],
      state: 'MAX_NPCS = 50; currentCount, lastSentCount, isDragging, and isHovering hold local UI state.',
      services: ['Players', 'ReplicatedStorage', 'UserInputService'], objects: ['NPCControlGui', 'CanPlaceAntenna attribute'],
      events: [['Sends / receives', 'NPCSpawnEvent', 'setCount/getCount and numeric count response'], ['Receives', 'ResetGame', 'sets the slider back to zero']],
      related: ['interface', 'experience/small-town']
    })
  ];

  const events = [
    { id: 'lab-frequencychangedevent', place: 'Material lab', name: 'FrequencyChangedEvent', direction: 'Client → server', sender: 'lab-room-one-dashboard', receivers: ['lab-player-signal-handler', 'lab-heatmap-handler'], arguments: 'frequencyBand: string, newMaxDistance: number', purpose: 'Changes per-player frequency attributes in PlayerSignalHandler; HeatmapHandler uses newMaxDistance as its heatmap distance limit. The two listeners read different portions of the same call.' },
    { id: 'lab-toggleheatmapevent', place: 'Material lab', name: 'ToggleHeatmapEvent', direction: 'Client → server', sender: 'lab-heatmap-toggle', receivers: ['lab-heatmap-handler'], arguments: 'update: "RSRP" | "SINR"', purpose: 'Switches which heatmap metric is drawn by the server updater.' },
    { id: 'lab-placeitemevent', place: 'Material lab', name: 'PlaceItemEvent', direction: 'Client → server', sender: 'lab-room-one-material-placer', receivers: ['lab-place-material-handler'], arguments: 'materialName: string, cf: CFrame', purpose: 'Requests an allowed material block placement; the server checks type, room, bounds, distance, and snapping.' },
    { id: 'lab-updateantennaevent', place: 'Material lab', name: 'UpdateAntennaEvent', direction: 'Client → server', sender: 'lab-slider-controls', receivers: ['lab-antenna-beam-simulation'], arguments: 'antennaType: string, elevation: number, azimuth: number', purpose: 'Updates the visual beam for a directional or narrow-beam antenna after a slider drag.' },
    { id: 'lab-npcspawnevent', place: 'Material lab', name: 'NPCSpawnEvent', direction: 'Two-way RemoteEvent', sender: 'lab-npc-control-script', receivers: ['lab-npc-spawner'], arguments: 'Request: action ("setCount" or "getCount"), optional targetCount. Response: count: number.', purpose: 'Synchronizes the room-one NPC population slider with the server count.' },
    { id: 'town-startgame', place: 'Small town', name: 'StartGame', direction: 'Server → client', sender: 'town-start-game', receivers: ['town-antennaplacer', 'town-third-person-camera', 'town-speed-control-script'], arguments: 'No explicit payload', purpose: 'Notifies the triggering player to begin the activity and update camera and speed controls.' },
    { id: 'town-resetgame', place: 'Small town', name: 'ResetGame', direction: 'Client → server → client', sender: 'town-antennaplacer', receivers: ['town-start-game', 'town-npc-spawner', 'town-speed-control-script', 'town-npc-control-script'], arguments: 'No explicit payload', purpose: 'Requests and acknowledges a reset; server scripts clear session state and related NPC connections.' },
    { id: 'town-placeantenna', place: 'Small town', name: 'PlaceAntenna', direction: 'Client → server', sender: 'town-antennaplacer', receivers: ['town-antenna-server'], arguments: 'antennaName: string, position: Vector3, rotationAngle: number', purpose: 'Requests a model clone at a chosen position and quarter-turn rotation.' },
    { id: 'town-deleteantenna', place: 'Small town', name: 'DeleteAntenna', direction: 'Client → server', sender: 'town-antennaplacer', receivers: ['town-antenna-server'], arguments: 'antennaInstanceName: string', purpose: 'Requests removal of a placed antenna after the server checks its Owner tag.' },
    { id: 'town-npcspawnevent', place: 'Small town', name: 'NPCSpawnEvent', direction: 'Two-way RemoteEvent', sender: 'town-npc-control-script', receivers: ['town-npc-spawner', 'town-town-dashboard-script'], arguments: 'Request: action ("add", "remove", "setCount", "getCount"), optional targetCount. Response: count: number.', purpose: 'Adjusts and reports NPC population; the dashboard also requests a count.' }
  ];

  const page = (id, title, group, summary, tags, body) => ({ id, title, group, summary, tags, body });
  const pages = [
    page('overview', 'Overview', 'Getting started', 'What the RAN Network Simulator is, who it serves, and where to begin reading the code.', ['RAN', 'Roblox', '2degrees', 'ShadowTech', 'Year 9–11'], () => `
      <div class="meta-row">${pill('Roblox Studio', 'blue')}${pill('Luau', 'blue')}${pill('2 places')}${pill('32 source files', 'orange')}</div>
      <h2 id="purpose">Purpose</h2>
      <p>The RAN Network Simulator is an educational Roblox experience for the 2degrees ShadowTech programme. It helps Year 9–11 students explore how distance, frequency choices, materials, antenna placement, and interference can change what a mobile network <em>appears</em> to do in a simplified simulation.</p>
      <p>The source tree contains two experiences: a <strong>material lab</strong> with room-based demonstrations and a <strong>small town</strong> with fixed towers and placeable antennas. Luau scripts manage the world interactions, server-side values, local visuals, and dashboards.</p>
      ${callout('info', 'Current implementation.', 'This documentation follows the Roblox Studio and Luau source. The earlier project proposal describes a phone, ADB, Python, and Matplotlib concept that was superseded during development.')}
      <h2 id="reading-map">Reading map</h2>
      <div class="card-grid">
        ${card('repository', 'Start here', 'Repository map', 'Find both places, their server scripts, client scripts, and shared module.')}
        ${card('architecture', 'Architecture', 'Runtime structure', 'Understand services, Workspace objects, attributes, and RemoteEvents.')}
        ${card('simulation/signal', 'Simulation', 'Signal metrics', 'Follow RSRP-like and SINR calculations and their display limits.')}
        ${card('code-reference', 'Reference', 'Script index', 'Open a conceptual reference page for every Luau source file.')}
      </div>
      <h2 id="scope">Documented scope</h2>
      <p>The source implements 4G/5G-labelled frequency choices, simulated signal values, material attenuation, RSRP and SINR displays, heatmaps, antenna patterns, NPC load, and gameplay controls. ${route('terminology', 'Terminology')} distinguishes the network concepts from the educational approximations used here.</p>
      <p>The source does not contain a computed RSRQ metric or the proposed hardware telemetry pipeline. See ${route('simulation/signal', 'signal metrics')} for the implemented formulas and their limits.</p>
      <h2 id="source-of-truth">Source of truth</h2>
      <p>Code behavior and exact file paths come from <code>src/Places</code>. The repository ${route('repository', 'map')} lists Studio objects referenced by those scripts. The README describes the current Roblox project; the proposal provides motivation and historical context. The supplied <code>Status Report.md</code> file is empty.</p>
    `),
    page('repository', 'Repository map', 'Getting started', 'How the two Roblox places and documentation files are arranged in the project source.', ['folders', 'paths', 'Studio', 'source tree'], () => `
      <h2 id="layout">Source layout</h2>
      ${code(`src/Places/\n├── material-lab/\n│   ├── ReplicatedStorage/FrequencyData.luau\n│   ├── ServerScriptService/       (7 server scripts)\n│   ├── StarterPlayer/             (4 client scripts)\n│   └── StarterGui/                (6 client scripts)\n└── small-town/\n    ├── ServerScriptService/       (8 server scripts)\n    ├── StarterPlayer/             (3 client scripts)\n    └── StarterGui/                (3 client scripts)`, 'Repository source directories').replace('<span class="language">Luau</span>', '<span class="language">Tree</span>')}
      <p>Those locations mirror Roblox service containers. <code>ServerScriptService</code> holds the server-side logic. <code>StarterPlayer</code> and <code>StarterGui</code> hold code intended to run on a player client. <code>ReplicatedStorage</code> holds the shared <code>FrequencyData</code> module and is referenced for RemoteEvents and assets.</p>
      <h2 id="place-boundary">Two separate places</h2>
      <p>The material lab and small town each have their own <code>NPCSpawner</code> and <code>NPCControlScript</code>. Their similarly named scripts implement place-specific behavior; do not treat them as one shared runtime. ${route('code-reference', 'The script index')} groups the exact paths by place.</p>
      <h2 id="studio-objects">Studio objects referenced by code</h2>
      ${table(['Material lab', 'Small town'], [[`<code>RoomOneZone</code>, <code>RoomTwoZone</code>, <code>SignalSourcesFolder</code>, <code>LevelOneMaterials</code>`, `<code>CellTowers</code>, <code>PlacedAntennas</code>, <code>TownAttenuationZones</code>, <code>NPCs</code>`], [`<code>LevelOne.HeatmapTile</code>, <code>PlaceableMaterials</code>, <code>DashboardGui</code>`, `<code>AntennaModels</code>, <code>StartButton.ProximityPrompt</code>, <code>DashboardGui</code>`]])}
      <h2 id="reading-source">Finding a feature</h2>
      <p>Start with a UI control in <code>StarterGui</code> or <code>StarterPlayer</code>, follow any ${route('events', 'RemoteEvent')} through <code>ReplicatedStorage</code>, then read its server handler. For displayed metrics, also follow the player attributes written by server scripts back to dashboard readers.</p>
    `),
    page('architecture', 'Runtime structure', 'Architecture', 'How Roblox server scripts, client scripts, shared data, and world objects fit together.', ['client server', 'Roblox services', 'ReplicatedStorage', 'Workspace'], () => `
      <h2 id="boundaries">Execution boundaries</h2>
      ${diagram([[{title:'Client scripts',note:'StarterPlayer and StarterGui',tone:'orange'},{title:'RemoteEvents',note:'ReplicatedStorage',tone:''},{title:'Server scripts',note:'ServerScriptService',tone:'green'}],[{title:'Client views',note:'Dashboards and local visuals',tone:'orange'},{title:'Player attributes + Workspace',note:'Replicated state and world objects',tone:''},{title:'Server estimates',note:'Signal, placement, NPCs, rooms',tone:'green'}]], 'RemoteEvents carry requests; attributes and Workspace state carry results back to clients.')}
      <p>Each place runs server scripts for authoritative world changes and calculated attributes. Client scripts handle pointer input, sliders, UI, camera behavior, and local visuals. The client sends requests through named RemoteEvents; server scripts may write player attributes that clients read each frame or on attribute changes.</p>
      <h2 id="services">Services in the source</h2>
      ${table(['Roblox service', 'Role in this project'], [['<code>Players</code>', 'Character lifecycle, LocalPlayer, and per-player attributes.'], ['<code>RunService</code>', 'Heartbeat sampling on the server and RenderStepped visual/UI updates on clients.'], ['<code>ReplicatedStorage</code>', 'RemoteEvents, material/antenna templates, heatmap tile template, and FrequencyData.'], ['<code>Workspace</code>', 'Zones, signal sources, towers, placed models, NPCs, visual folders, and raycasts.'], ['<code>UserInputService</code>', 'Cursor, keyboard, touch, and slider input.'], ['<code>PhysicsService</code>', 'NPC collision group setup.'], ['<code>TweenService</code>', 'Room-one dashboard and camera zoom transitions.']])}
      <h2 id="state">State distribution</h2>
      <p><strong>Player attributes</strong> carry values such as <code>InRoomOne</code>, <code>FrequencyBand</code>, <code>RSRP</code>, <code>SINR</code>, and town antenna selection fields. <strong>Workspace objects</strong> carry placed materials, antennas, NPCs, and drawn visual parts. <strong>Local tables</strong> hold script-specific configuration or cached state, such as noise history and NPC tower connection counts.</p>
      <p>The material lab uses ${scriptLink('lab-frequency-data','FrequencyData')} as a shared lookup. Small-town frequency tables are local to individual scripts, so the two places do not use one common frequency module.</p>
      <h2 id="assumptions">Script roles</h2>
      <p>The paths group server scripts in <code>ServerScriptService</code>, client scripts in <code>StarterPlayer</code> and <code>StarterGui</code>, and the shared <code>FrequencyData</code> module in <code>ReplicatedStorage</code>. FrequencyData returns a table used by the room-one dashboard and signal handler.</p>
      <p>Continue with ${route('data-flow', 'Data flow')} for request-to-display traces, or browse ${route('code-reference', 'all script pages')}.</p>
    `),
    page('data-flow', 'Data flow', 'Architecture', 'Concrete request and update paths through RemoteEvents and attributes.', ['RemoteEvent', 'attributes', 'communication', 'FrequencyChangedEvent'], () => `
      <h2 id="frequency-path">Frequency change in the material lab</h2>
      ${diagram([[{title:'RoomOneDashboard',note:'frequency slider',tone:'orange'},{title:'FrequencyChangedEvent',note:'band + maxDistance'},{title:'PlayerSignalHandler',note:'per-player frequency attributes',tone:'green'}],[{title:'HeatmapHandler',note:'global maxDistance',tone:'green'},{title:'Player attributes',note:'RSRP, SINR, source data'},{title:'RoomOneDashboard',note:'rendered metrics',tone:'orange'}]], 'The same RemoteEvent has two server listeners with distinct responsibilities.')}
      <p>${scriptLink('lab-room-one-dashboard','RoomOneDashboard')} sends a band and maximum distance. ${scriptLink('lab-player-signal-handler','PlayerSignalHandler')} validates the band against ${scriptLink('lab-frequency-data','FrequencyData')} and updates that player's frequency attributes and signal immediately. ${scriptLink('lab-heatmap-handler','HeatmapHandler')} assigns the submitted maximum distance to its heatmap calculation state. Subsequent Heartbeat updates recolor tiles. See ${eventLink('FrequencyChangedEvent')}.</p>
      <h2 id="material-path">Material placement and signal</h2>
      <p>${scriptLink('lab-room-one-material-placer','RoomOneMaterialPlacer')} builds a local preview and sends <code>materialName</code> plus a proposed <code>CFrame</code> through ${eventLink('PlaceItemEvent')}. ${scriptLink('lab-place-material-handler','PlaceMaterialHandler')} validates the request and clones the material into <code>LevelOneMaterials</code>. ${scriptLink('lab-player-signal-handler','PlayerSignalHandler')} includes this folder in its material raycast, while ${scriptLink('lab-heatmap-handler','HeatmapHandler')} tests overlap along a source path.</p>
      <h2 id="town-path">Small-town antenna placement</h2>
      <p>${scriptLink('town-antennaplacer','Antennaplacer')} submits a model name, position, and angle via ${eventLink('PlaceAntenna','PlaceAntenna','small-town')}. ${scriptLink('town-antenna-server','AntennaServer')} validates and adds the model to <code>PlacedAntennas</code>. ${scriptLink('town-antenna-signal-manager','AntennaSignalManager')} includes that folder in its next player update; ${scriptLink('town-cell-tower-visualizer','CellTowerVisualizer')} includes it in the coverage display.</p>
      <h2 id="attribute-path">Why attributes matter</h2>
      <p>Player attributes are the read side of several flows. For example, <code>RSRP</code> and <code>SINR</code> are written by the material-lab signal handler and read by the room-one dashboard. Town <code>PlacedAntenna*</code> attributes are written by AntennaSignalManager and read by TownDashboardScript. The ${route('events', 'event reference')} lists both RemoteEvents and important replicated attributes.</p>
    `),
    page('simulation/signal', 'Signal metrics', 'Simulation', 'The implemented signal, RSRP-like, SINR, interference, and noise calculations.', ['RSRP', 'SINR', 'RSRQ', 'dBm', 'interference', 'signal strength'], () => `
      ${callout('info', 'Educational model.', 'The values below are simulation estimates for instruction and UI. Their formulas are specific to this project and should not be interpreted as standards-compliant radio measurements.')}
      <h2 id="material-rsrp">Material-lab RSRP-like value</h2>
      <p>${scriptLink('lab-player-signal-handler','PlayerSignalHandler')} chooses the closest child of <code>SignalSourcesFolder</code>. It starts at <code>-50</code>, subtracts distance divided by the selected <code>FrequencyDivisor</code>, then subtracts the first configured material hit's <code>Attenuation</code> attribute. It bounds the value between <code>-120</code> and <code>-50</code> dBm and adds a smoothed small random offset before publishing <code>RSRP</code>.</p>
      ${code(`local baseSignal = math.clamp(\n\t-50 - towerDistance / rangeDivisor,\n\t-120,\n\t-50\n)`, 'PlayerSignalHandler.luau · calculateRSRP')}
      <h2 id="sinr">Material-lab SINR</h2>
      <p>The same handler estimates each configured source at the player position. It converts source levels from dBm to linear milliwatts, treats the closest source as serving power, sums the other sources as interference, adds a fixed <code>-100 dBm</code> noise floor, and calculates a power ratio in decibels. The displayed value is floored and clamped to <code>0–20 dB</code>.</p>
      <p>Because source selection is by nearest distance and the source model is simplified, this is a teaching visualization of SINR behavior. ${route('simulation/heatmap', 'The heatmap')} has a related but separate SINR routine and a <code>-104 dBm</code> noise floor.</p>
      <h2 id="town-signal">Small-town estimates</h2>
      <p>${scriptLink('town-tower-signal-manager','TowerSignalManager')} estimates a fixed tower's player signal from distance in studs divided by ten, a frequency divisor, tower power offset, and the player's material attenuation attribute. ${scriptLink('town-antenna-signal-manager','AntennaSignalManager')} chooses the closest in-range fixed or placed model when possible. For a selected placed antenna, it subtracts <code>2</code> per tracked NPC connection before a small noise adjustment. These are distinct calculations and publish different attributes.</p>
      ${code(`local scaledDistance = closest.dist / 10\nlocal baseSignal = -50 - (scaledDistance / divisor)`, 'AntennaSignalManager.luau · distance estimate')}
      <h2 id="rsrq">RSRQ status</h2>
      ${callout('warning', 'Not implemented in the Luau source.', 'RSRQ is part of the project’s educational subject matter, but no current Luau routine calculates or displays an RSRQ value. Do not read the RSRP or SINR outputs as RSRQ.')}
      <p>Related: ${route('simulation/frequency', 'frequency and range')}, ${route('simulation/materials', 'materials')}, ${route('terminology', 'terminology')}, and ${scriptLink('lab-player-signal-handler','the signal handler reference')}.</p>
    `),
    page('simulation/frequency', 'Frequency and range', 'Simulation', 'How selectable bands influence per-player signal estimates and heatmap distance.', ['4G', '5G', '700 MHz', '1800 MHz', '2100 MHz', '3500 MHz', 'FrequencyChangedEvent'], () => `
      <h2 id="bands">Material-lab band table</h2>
      <p>${scriptLink('lab-frequency-data','FrequencyData')} defines four choices. Their 4G/5G labels appear in the shared data. The <code>divisor</code> is a simulation parameter: smaller values make the distance term larger in the player signal formula.</p>
      ${table(['Display name', 'Band key', 'Divisor', 'Max distance'], [['4G 700 MHz','<code>700 MHz</code>','1.2','45'], ['4G 1800 MHz','<code>1800 MHz</code>','0.9','40'], ['4G 2100 MHz','<code>2100 MHz</code>','0.7','35'], ['5G 3500 MHz','<code>3500 MHz</code>','0.5','30']])}
      <p>The module's default is <code>3500 MHz</code>. ${scriptLink('lab-room-one-dashboard','RoomOneDashboard')} sends the selected band and maxDistance through ${eventLink('FrequencyChangedEvent')}. ${scriptLink('lab-player-signal-handler','PlayerSignalHandler')} uses the band lookup; ${scriptLink('lab-heatmap-handler','HeatmapHandler')} uses the distance argument to change its tile mapping.</p>
      <h2 id="small-town">Small-town frequency data</h2>
      <p>Small-town signal and visualizer scripts carry local tables for the same four band keys and divisors. Their default is <code>2100 MHz</code>. In that place, fixed and placed antenna outer radii are multiplied by a frequency divisor in ${scriptLink('town-antenna-signal-manager','AntennaSignalManager')} and ${scriptLink('town-cell-tower-visualizer','CellTowerVisualizer')}.</p>
      ${callout('info', 'Scope of the numbers.', 'The numeric divisors and ranges are authored simulation settings. The repository does not establish that they reproduce measured 4G or 5G propagation in a real environment.')}
      <h2 id="where-to-edit">Configuration locations</h2>
      <p>See ${route('configuration', 'Data and configuration')} for exact files and other constants. The material-lab module is shared; the small-town tables are script-local.</p>
    `),
    page('simulation/materials', 'Materials and attenuation', 'Simulation', 'How placed blocks and town zones affect simulated signal attributes and heatmap tiles.', ['attenuation', 'concrete', 'metal', 'wood', 'raycast', 'obstacles'], () => `
      <h2 id="lab-placement">Placed materials in room one</h2>
      <p>${scriptLink('lab-room-one-material-placer','RoomOneMaterialPlacer')} lets a player select Concrete, Metal, or Wood, preview a grid position, and send a placement request. ${scriptLink('lab-place-material-handler','PlaceMaterialHandler')} validates the request on the server, snaps it to the configured 2 stud grid, and places the clone in <code>LevelOneMaterials</code>.</p>
      <p>${scriptLink('lab-player-signal-handler','PlayerSignalHandler')} raycasts from the player toward a source with an Include filter for that material folder. It reads the first hit's <code>Attenuation</code> attribute and subtracts it from its signal estimate. The numeric attenuation attributes live on Roblox objects; their values are not present in the Luau source.</p>
      <h2 id="heatmap-obstacles">Heatmap obstacle choice</h2>
      <p>${scriptLink('lab-heatmap-handler','HeatmapHandler')} checks a thin oriented box between a tile and antenna. If multiple placed blocks overlap that volume, it chooses by explicit priority: <strong>Metal → Concrete → Wood</strong>. The chosen block's attenuation is scaled by an exponential shadow falloff based on tile-to-material distance.</p>
      <h2 id="town-zones">Small-town detectors</h2>
      <p>${scriptLink('town-ray-material-detection','RayMaterialDetection')} casts toward the nearest fixed tower through <code>TownAttenuationZones</code> and writes <code>Material</code> and <code>Attenuation</code>. ${scriptLink('town-wall-detection','WallDetection')} also writes those attributes by inspecting parts overlapping its visual ray toward <code>Source</code>. Both scripts are present; the source does not define a single precedence rule between their updates.</p>
      <p>The town's ${scriptLink('town-tower-signal-manager','TowerSignalManager')} reads the attenuation attribute. The material-lab and town systems therefore use different world objects and detection methods.</p>
      ${callout('info', 'Where losses are configured.', 'The scripts read the Attenuation attribute from material models or zones. Inspect those Studio objects when adjusting the loss values; the Luau source does not define a complete table of them.')}
    `),
    page('simulation/heatmap', 'Heatmap generation', 'Simulation', 'Grid creation, incremental RSRP/SINR updates, colors, and mode switching.', ['heatmap', 'RSRP', 'SINR', 'tiles', 'ToggleHeatmapEvent'], () => `
      <h2 id="grid">Tile grid</h2>
      <p>${scriptLink('lab-heatmap-handler','HeatmapHandler')} clones <code>LevelOne.HeatmapTile</code> into a <code>HeatmapGrid</code> folder: <strong>24 rows × 30 columns</strong> with 2 stud spacing, centered around <code>Vector3.new(32, 0.5, -10)</code>. A red-to-yellow-to-green color map represents normalized values with a small visual noise amount.</p>
      <p>Each <code>Heartbeat</code> updates 30 randomly chosen tiles; the grid is therefore refreshed incrementally, not as one full synchronous pass. <code>signalSources</code> is captured from <code>SignalSourcesFolder:GetChildren()</code> when the script starts.</p>
      <h2 id="rsrp-tiles">RSRP tile estimate</h2>
      <p>For each chosen tile, the script maps distance from each source linearly across <code>maxDistance</code> between the configured <code>-50</code> and <code>-120 dBm</code> bounds. It applies at most one prioritized material loss with distance-dependent falloff, then uses the strongest source's estimate to color the tile.</p>
      <h2 id="sinr-tiles">SINR tile estimate</h2>
      <p>For SINR mode, source estimates are converted to milliwatts. The strongest source is the serving power; all other source powers form the interference term. A <code>-104 dBm</code> noise floor is added before conversion back to dB and color normalization over <code>-10 to 30 dB</code>.</p>
      ${code(`local interferencePower = totalReceivedPower - strongestSignalPower\nlocal noisePower = dBmToMilliwatts(NOISE_FLOOR_DBM)`, 'HeatmapHandler.luau · updateSINR')}
      <h2 id="controls">Mode and frequency controls</h2>
      <p>${scriptLink('lab-heatmap-toggle','HeatmapToggle')} sends <code>"RSRP"</code> or <code>"SINR"</code> through ${eventLink('ToggleHeatmapEvent')}. ${eventLink('FrequencyChangedEvent')} updates the heatmap's distance limit from the submitted <code>newMaxDistance</code> argument. Both mode and range are script-level state in this server handler, so they are shared by its grid rather than maintained per player.</p>
      <p>Related: ${route('simulation/signal','signal metrics')}, ${route('simulation/materials','material handling')}, and ${route('configuration','configuration')}.</p>
    `),
    page('simulation/antennas', 'Antennas and coverage', 'Simulation', 'How antenna patterns, placement, coverage spheres, and NPC load are visualized.', ['antenna', 'beamforming', 'azimuth', 'elevation', 'coverage', 'NPC'], () => `
      <h2 id="lab-patterns">Material-lab patterns</h2>
      <p>${scriptLink('lab-antenna-beam-simulation','AntennaBeamSimulation')} creates point clouds for directional, narrow, and omnidirectional antenna visuals. The directional routine maps sample points into antenna-local coordinates, computes horizontal and vertical angular offsets, reduces a modeled gain from its peak, and maps bounded strength to point position and color. The omnidirectional visualization uses a vertical-angle pattern.</p>
      <p>${scriptLink('lab-slider-controls','SliderControls')} sends elevation and azimuth through ${eventLink('UpdateAntennaEvent')}. The server accepts Directional or NarrowBeam values and updates the matching visualization. ${scriptLink('lab-room-detection','RoomDetection')} separately publishes nearby antenna characteristics as player attributes for UI panels.</p>
      ${callout('info', 'Visual boundary.', 'The beam visualization script updates drawn patterns. The current PlayerSignalHandler calculates player RSRP and SINR from source distance and material attenuation; it does not consume those beam point strengths.')}
      <h2 id="town-placement">Small-town placement</h2>
      <p>${scriptLink('town-antennaplacer','Antennaplacer')} creates a preview and budget UI. The client sends ${eventLink('PlaceAntenna','PlaceAntenna','small-town')} to ${scriptLink('town-antenna-server','AntennaServer')}, which clones a permitted template, aligns its base, tags its owner, and parents it under <code>PlacedAntennas</code>. The matching delete request checks that owner tag.</p>
      <h2 id="coverage">Range and score</h2>
      <p>${scriptLink('town-cell-tower-visualizer','CellTowerVisualizer')} draws three concentric spheres per tower or placed model. It estimates coverage by testing 50 × 50 points over fixed map bounds against outer spheres, then writes <code>CoverageScore</code>. ${scriptLink('town-antenna-signal-manager','AntennaSignalManager')} selects a nearby model for dashboard signal and subtracts a load penalty for NPCs on placed antennas.</p>
      <p>These radii and patterns are educational visuals, not a physical propagation solver. See ${route('simulation/signal','signal metrics')} and ${route('experience/small-town','the small-town activity')}.</p>
    `),
    page('experience/material-lab', 'Material lab', 'Experiences', 'The room-one and room-two interactive demonstrations implemented in the material-lab place.', ['room one', 'room two', 'materials', 'frequency', 'antenna'], () => `
      <h2 id="rooms">Room state</h2>
      <p>${scriptLink('lab-room-detection','RoomDetection')} tests the player root against <code>RoomOneZone</code> and <code>RoomTwoZone</code> every 0.1 seconds. It publishes <code>InRoomOne</code> and <code>InRoomTwo</code> attributes when state changes. Those flags show and hide dashboards, change camera zoom, and trigger the character shrink behavior in room one.</p>
      <h2 id="room-one">Room one · materials and signal</h2>
      <p>The player can place Concrete, Metal, or Wood blocks on the heatmap area using ${scriptLink('lab-room-one-material-placer','RoomOneMaterialPlacer')}. A local ${scriptLink('lab-ray-visual','RayVisual')} part connects the character to <code>SignalSource</code>. The server's ${scriptLink('lab-player-signal-handler','PlayerSignalHandler')} updates distance, material, RSRP, and SINR attributes; ${scriptLink('lab-room-one-dashboard','RoomOneDashboard')} displays them and exposes a frequency slider. The heatmap button switches between RSRP and SINR views.</p>
      <h2 id="room-two">Room two · antenna patterns</h2>
      <p>Room two shows antenna characteristics and a local nearest-antenna signal estimate in ${scriptLink('lab-room-two-dashboard','RoomTwoDashboard')}. ${scriptLink('lab-slider-controls','SliderControls')} exposes elevation for a directional antenna and elevation plus azimuth for NarrowBeam. The settings are sent to ${scriptLink('lab-antenna-beam-simulation','AntennaBeamSimulation')} for visual updates. ${scriptLink('lab-pop-up-script','PopUpScript')} shows type-specific explanatory text.</p>
      <h2 id="npc">NPC control</h2>
      <p>${scriptLink('lab-npc-control-script','NPCControlScript')} displays a room-one count slider. ${scriptLink('lab-npc-spawner','NPCSpawner')} maintains the server population, with a configured cap of 50 NPCs.</p>
    `),
    page('experience/small-town', 'Small town', 'Experiences', 'The fixed-tower and player-placed-antenna activity in the small-town place.', ['town', 'tower', 'placement', 'coverage', 'NPC'], () => `
      <h2 id="session">Starting and resetting</h2>
      <p>${scriptLink('town-start-game','StartGame')} listens to the <code>StartButton</code> proximity prompt, records the active player, and fires ${eventLink('StartGame','StartGame','small-town')} to that client. A reset request through ${eventLink('ResetGame','ResetGame','small-town')} removes that player's owned antennas, clears NPCs, restores speed, moves the character near <code>SpawnLocation</code>, and notifies the client.</p>
      <h2 id="antennas">Building coverage</h2>
      <p>${scriptLink('town-antennaplacer','Antennaplacer')} presents four priced antenna options, a placement preview, rotation, deletion, and a budget starting at 1000. ${scriptLink('town-antenna-server','AntennaServer')} validates and clones models. ${scriptLink('town-cell-tower-visualizer','CellTowerVisualizer')} can show range spheres and a coverage percentage, which the placement UI uses for results.</p>
      <h2 id="signal">Moving through the network</h2>
      <p>${scriptLink('town-tower-signal-manager','TowerSignalManager')} samples fixed-tower signal and material attenuation. ${scriptLink('town-antenna-signal-manager','AntennaSignalManager')} also considers placed antennas and their NPC load for the town dashboard. ${scriptLink('town-ray-material-detection','RayMaterialDetection')} reads attenuation zones; ${scriptLink('town-wall-detection','WallDetection')} inspects overlap along a visual ray.</p>
      <h2 id="support">Supporting systems</h2>
      <p>${scriptLink('town-npc-spawner','NPCSpawner')} creates wandering NPCs and tracks their nearest tower connection counts. ${scriptLink('town-npc-control-script','NPCControlScript')} adjusts population. ${scriptLink('town-speed-control-script','SpeedControlScript')} and ${scriptLink('town-third-person-camera','ThirdPersonCamera')} provide movement and zoom controls. ${scriptLink('town-led-manager','LEDManager')} changes marked LED visibility with time of day.</p>
    `),
    page('interface', 'User interface', 'Experiences', 'Which client scripts render controls and how server state reaches each dashboard.', ['dashboard', 'slider', 'UI', 'status badges'], () => `
      <h2 id="lab-ui">Material-lab panels</h2>
      ${table(['UI script', 'Reads or sends', 'Visible effect'], [[scriptLink('lab-room-one-dashboard','RoomOneDashboard'), 'Player RSRP, SINR, material, source and distance; sends FrequencyChangedEvent.', 'Signal bars, status badges, material insight, tower and capacity display, frequency slider.'], [scriptLink('lab-room-two-dashboard','RoomTwoDashboard'), 'Room flags and antenna attributes; computes a local distance estimate.', 'Room-two signal and antenna panel.'], [scriptLink('lab-slider-controls','SliderControls'), 'ClosestSignalSource and InRoomTwo; sends UpdateAntennaEvent.', 'Azimuth and elevation sliders.'], [scriptLink('lab-heatmap-toggle','HeatmapToggle'), 'Sends ToggleHeatmapEvent.', 'RSRP/SINR mode button.'], [scriptLink('lab-pop-up-script','PopUpScript'), 'Antenna attributes.', 'Antenna details popup.'], [scriptLink('lab-npc-control-script','NPCControlScript'), 'NPCSpawnEvent count.', 'NPC count slider.']])}
      <h2 id="town-ui">Small-town panels</h2>
      ${table(['UI script', 'Reads or sends', 'Visible effect'], [[scriptLink('town-town-dashboard-script','TownDashboardScript'), 'PlacedAntenna* player attributes and NPC count.', 'Signal, range, source, and load cards.'], [scriptLink('town-antennaplacer','Antennaplacer'), 'PlaceAntenna/DeleteAntenna/ResetGame and CoverageScore.', 'Placement preview, antenna choice, budget, results.'], [scriptLink('town-cell-tower-visualizer','CellTowerVisualizer'), 'Tower models and FrequencyBand.', 'Coverage spheres, score indicator, toggle.'], [scriptLink('town-speed-control-script','SpeedControlScript'), 'User input and StartGame/ResetGame.', 'Speed slider.'], [scriptLink('town-npc-control-script','NPCControlScript'), 'NPCSpawnEvent.', 'NPC count slider.']])}
      <h2 id="refresh">Refresh behavior</h2>
      <p>Several dashboards read replicated player attributes in <code>RenderStepped</code> handlers. Other controls use <code>GetAttributeChangedSignal</code> for room visibility or antenna labels. World calculations run in server <code>Heartbeat</code> loops; the UI may update more often than those values change.</p>
      <p>For exact event payloads, use ${route('events','Events and communication')}. For each script's functions and paths, use ${route('code-reference','the script index')}.</p>
    `),
    page('terminology', 'Terminology and limits', 'Simulation', 'The network vocabulary used by this simulator and the boundaries of its simplified models.', ['RAN', 'RSRP', 'RSRQ', 'SINR', 'dBm', '4G', '5G'], () => `
      <h2 id="terms">Terms used in the project</h2>
      ${table(['Term', 'Meaning in this documentation'], [['RAN', 'Radio Access Network: the mobile access side that connects devices to cell sites. The experience uses towers and antennas as visual teaching elements.'], ['4G / 5G', 'Labels attached to selectable bands in FrequencyData. The Luau formulas are authored simulation behavior, not a network protocol implementation.'], ['dBm', 'A logarithmic power unit used for displayed signal levels and conversions in the SINR estimate.'], ['RSRP', 'Reference Signal Received Power. Scripts use the name RSRP for a bounded distance-and-attenuation estimate; they do not implement a standards measurement pipeline.'], ['SINR', 'Signal-to-Interference-plus-Noise Ratio. Player and heatmap scripts compare one serving estimate against other source estimates and a configured noise floor.'], ['RSRQ', 'Reference Signal Received Quality. This term appears in project goals but has no calculation in the current Luau source.'], ['Attenuation', 'A loss value read from material or zone attributes configured on Studio objects.'], ['Beamforming', 'Here, a visual antenna pattern updated by orientation sliders. It is not fed into the player signal formula.']])}
      <h2 id="models">Model boundaries</h2>
      <p>The player, heatmap, and small-town systems use related but separate settings, clamps, noise floors, and source selection rules. A value shown on one UI should be read as that script's simulation output. The site names the responsible script whenever it explains a formula.</p>
      <p>Start with ${route('simulation/signal','signal metrics')} or ${route('simulation/antennas','antenna visuals')} for implementation details.</p>
    `),
    page('configuration', 'Data and configuration', 'Reference', 'Where band, grid, range, material, NPC, and display settings live in source.', ['config', 'FrequencyData', 'constants', 'attenuation', 'heatmap'], () => `
      <h2 id="frequency">Frequency configuration</h2>
      <p>${scriptLink('lab-frequency-data','FrequencyData')} is the material-lab shared module. It provides <code>Options</code>, <code>ByBand</code>, and <code>Default</code>. The visible room-one slider also defines a local <code>frequencyOptions</code> list. Small-town ${scriptLink('town-tower-signal-manager','TowerSignalManager')}, ${scriptLink('town-antenna-signal-manager','AntennaSignalManager')}, and ${scriptLink('town-cell-tower-visualizer','CellTowerVisualizer')} use their own frequency tables.</p>
      ${code(`FrequencyData.Default = FrequencyData.ByBand["3500 MHz"]`, 'FrequencyData.luau · default band')}
      <h2 id="geometry">Grid and geometry</h2>
      ${table(['Setting', 'Value / location', 'Used for'], [['Heatmap tiles', '<code>ROWS = 24</code>, <code>COLUMNS = 30</code>, <code>SPACING = 2</code> in HeatmapHandler.', 'Creates the server tile grid.'], ['Heatmap update batch', '<code>updatesPerFrame = 30</code> in HeatmapHandler.', 'Random tile recoloring each Heartbeat.'], ['Material placement grid', '<code>GRID_SIZE = 2</code> in PlaceMaterialHandler; matching client settings.', 'Snapping placed blocks.'], ['Town coverage sample', '<code>gridSize = 50</code> in CellTowerVisualizer.', 'Estimates a percentage over fixed MAP_BOUNDS.']])}
      <h2 id="signal-values">Signal and antenna settings</h2>
      <p>The material-lab player calculation clamps RSRP-like values to <code>-120..-50</code> and displays SINR in <code>0..20 dB</code> with a <code>-100 dBm</code> noise floor. The heatmap uses its own RSRP bounds and a <code>-104 dBm</code> SINR noise floor. Its material priority is Metal (3), Concrete (2), then Wood (1).</p>
      <p>The small-town range tables depend on script: ${scriptLink('town-antenna-signal-manager','AntennaSignalManager')} and ${scriptLink('town-cell-tower-visualizer','CellTowerVisualizer')} use 20/40/60/90 type values, while ${scriptLink('town-tower-signal-manager','TowerSignalManager')} stores a 140 value for its Lattice tower type. Consult each script before changing or interpreting a range.</p>
      <h2 id="object-attributes">Object attributes</h2>
      <p>Many values come from Studio objects rather than literal Luau constants: material <code>Attenuation</code>, tower <code>TowerType</code>, <code>TowerName</code>, and <code>MaxPower</code>, and model <code>SignalOrigin</code>. Inspect the place models or Studio properties for their configured values.</p>
      <h2 id="npc-settings">NPC settings</h2>
      <p>Both NPC spawners cap population at 50. The town spawner tracks <code>NPCConnections</code> on towers and antennas; ${scriptLink('town-antenna-signal-manager','AntennaSignalManager')} uses the count as a signal penalty for placed antennas.</p>
    `),
    page('developer-guide', 'Developer guide', 'Reference', 'How to trace, verify, and maintain features across the two places.', ['maintain', 'extend', 'trace', 'Roblox Studio'], () => `
      <h2 id="feature-trace">Trace a feature through the code</h2>
      <ol><li>Find the player control in <code>StarterGui</code> or <code>StarterPlayer</code>.</li><li>Look for a ${route('events','RemoteEvent')} or player attribute name used by that control.</li><li>Follow the event into <code>ServerScriptService</code>, or find the script writing the attribute.</li><li>Check dependent Workspace and ReplicatedStorage object names in that handler.</li><li>Return to the UI reader to see how the value is presented.</li></ol>
      <p>Example: frequency slider → ${scriptLink('lab-room-one-dashboard','RoomOneDashboard')} → ${eventLink('FrequencyChangedEvent')} → ${scriptLink('lab-player-signal-handler','PlayerSignalHandler')} and ${scriptLink('lab-heatmap-handler','HeatmapHandler')} → player metrics and tiles.</p>
      <h2 id="place-specific">Keep place-specific paths clear</h2>
      <p>The two places have separate NPC scripts, dashboards, signal models, and frequency state. Some event names recur in both places; interpret an event within its place. The ${route('code-reference','script index')} shows exact paths and execution roles.</p>
      <h2 id="changing-models">When a simulation setting changes</h2>
      <p>Identify every copy of a value before editing: material-lab frequency choices are present in ${scriptLink('lab-frequency-data','FrequencyData')} and the dashboard slider, while small-town scripts have independent tables. Heatmap, player metrics, and visual coverage each use different calculations. Document which display a change is meant to affect, then verify its event payload, server handler, and UI reader.</p>
      <h2 id="studio-dependencies">Roblox Studio dependencies</h2>
      <p>Many scripts use <code>WaitForChild</code> or <code>FindFirstChild</code> for templates, folders, zones, and RemoteEvents. The ${route('repository','repository map')} lists key object names; inspect the place hierarchy and object attributes in Roblox Studio when connecting or extending a feature.</p>
      <h2 id="evidence-limits">Evidence limits</h2>
      <p>The proposal establishes the 2degrees ShadowTech educational motivation, while the Luau source establishes current implementation. The supplied Status Report file contains no content. No ADB, Python telemetry pipeline, live phone data, or RSRQ calculation appears in the current source. The beam visualization also operates separately from player signal scoring.</p>
    `)
  ];

  const eventRows = (place) => events.filter((event) => event.place === place).map((event) => [
    `<span id="${event.id}"></span><code>${h(event.name)}</code><br><small>${h(event.direction)}</small>`,
    scriptLink(event.sender, scripts.find((item) => item.id === event.sender)?.name || event.sender),
    event.receivers.map((id) => scriptLink(id, scripts.find((item) => item.id === id)?.name || id)).join(', '),
    `<code>${h(event.arguments)}</code><br>${h(event.purpose)}`
  ]);

  pages.push(page('events', 'Events and communication', 'Architecture', 'RemoteEvent payloads, senders, receivers, and replicated attribute flows.', ['RemoteEvent', 'FrequencyChangedEvent', 'ToggleHeatmapEvent', 'NPCSpawnEvent', 'PlaceAntenna', 'ResetGame'], () => `
    <h2 id="lab-events">Material-lab RemoteEvents</h2>
    ${table(['Event', 'Sender', 'Receiver', 'Arguments and purpose'], eventRows('Material lab'))}
    <h2 id="town-events">Small-town RemoteEvents</h2>
    ${table(['Event', 'Sender', 'Receiver', 'Arguments and purpose'], eventRows('Small town'))}
    <h2 id="attributes">Player attributes</h2>
    ${table(['Place', 'Written by', 'Important values and readers'], [
      ['Material lab', scriptLink('lab-room-detection','RoomDetection'), '<code>InRoomOne</code>, <code>InRoomTwo</code>, antenna type and angles → camera, dashboards, popup, and controls.'],
      ['Material lab', scriptLink('lab-player-signal-handler','PlayerSignalHandler'), '<code>FrequencyBand</code>, <code>FrequencyDivisor</code>, <code>RSRP</code>, <code>SINR</code>, <code>Material</code>, <code>Attenuation</code>, <code>TowerDistance</code>, <code>ClosestSignalSource</code> → room dashboards and controls.'],
      ['Small town', scriptLink('town-ray-material-detection','RayMaterialDetection') + ' / ' + scriptLink('town-wall-detection','WallDetection'), '<code>Material</code> and <code>Attenuation</code> → TowerSignalManager; both detectors write these names.'],
      ['Small town', scriptLink('town-antenna-signal-manager','AntennaSignalManager'), '<code>PlacedAntennaName</code>, <code>PlacedAntennaSignal</code>, <code>PlacedAntennaNPCLoad</code>, <code>PlacedAntennaInRange</code> → TownDashboardScript.'],
      ['Small town', scriptLink('town-cell-tower-visualizer','CellTowerVisualizer'), '<code>CoverageScore</code> → antenna placement results UI. This LocalScript writes the attribute on the client.']
    ])}
    <p>Follow complete feature paths in ${route('data-flow','Data flow')}; the ${route('code-reference','script index')} gives per-file interfaces.</p>
  `));

  pages.push(page('code-reference', 'Script index', 'Reference', 'All 32 Luau files, grouped by place with a conceptual reference page for each one.', ['scripts', 'ModuleScript', 'LocalScript', 'Script', 'paths'], () => `
    <p>Each script page records its exact path, execution side, main functions, state, services, Roblox objects, and communication points.</p>
    <div class="script-filters" role="group" aria-label="Filter scripts by place">
      <button class="filter-button active" type="button" data-filter="all" aria-pressed="true">All <span>${scripts.length}</span></button>
      <button class="filter-button" type="button" data-filter="material-lab" aria-pressed="false">Material lab <span>${scripts.filter((item) => item.place === 'material-lab').length}</span></button>
      <button class="filter-button" type="button" data-filter="small-town" aria-pressed="false">Small town <span>${scripts.filter((item) => item.place === 'small-town').length}</span></button>
    </div>
    <h2 id="material-lab-scripts">Material lab</h2>
    <div class="reference-grid">${scripts.filter((item) => item.place === 'material-lab').map((item) => `<a class="reference-item" data-script-place="material-lab" href="#/script/${item.id}"><strong>${h(item.name)} →</strong><code>${h(item.path)}</code><p>${h(item.summary)}</p></a>`).join('')}</div>
    <h2 id="small-town-scripts">Small town</h2>
    <div class="reference-grid">${scripts.filter((item) => item.place === 'small-town').map((item) => `<a class="reference-item" data-script-place="small-town" href="#/script/${item.id}"><strong>${h(item.name)} →</strong><code>${h(item.path)}</code><p>${h(item.summary)}</p></a>`).join('')}</div>
  `));

  const scriptBody = (item) => {
    const remoteRows = item.events.map(([direction, name, description]) => [
      h(direction),
      events.some((event) => event.name === name && (item.place === 'material-lab' ? event.place === 'Material lab' : event.place === 'Small town'))
        ? eventLink(name, name, item.place) : `<code>${h(name)}</code>`,
      h(description)
    ]);
    return `
      <div class="meta-row">${pill(item.place === 'material-lab' ? 'Material lab' : 'Small town', 'blue')}${pill(item.runtime)}${pill(item.kind, 'orange')}</div>
      <p class="script-path"><code class="path-code">${h(item.path)}</code></p>
      <div class="script-details"><div class="script-detail"><b>Expected Roblox class</b><span>${h(item.kind)} · ${h(item.runtime.toLowerCase())}</span></div><div class="script-detail"><b>Location</b><span>${h(item.path.split('/').slice(3,-1).join('/'))}</span></div></div>
      <h2 id="purpose">Purpose</h2><p>${h(item.summary)}</p>
      <h2 id="functions">Main functions and behavior</h2>
      <ul class="compact-list">${(item.functions.length ? item.functions : ['No named functions; its current behavior is contained directly in the script body.']).map((entry) => `<li>${h(entry)}</li>`).join('')}</ul>
      <h2 id="state">State and configuration</h2><p>${h(item.state || 'No independent configuration is defined in this file.')}</p>
      <h2 id="communication">Events and shared values</h2>
      ${remoteRows.length ? table(['Direction', 'Event or state', 'Role'], remoteRows) : '<p>This file does not fire or handle a RemoteEvent. Its role is local data or a simple standalone behavior.</p>'}
      <h2 id="dependencies">Dependencies</h2>
      ${table(['Category', 'Used here'], [['Roblox services / context', h(item.services.length ? item.services.join(', ') : 'No service calls in this file.')], ['Named objects or attributes', h(item.objects.length ? item.objects.join(', ') : 'No named external object dependency.')], ['Modules', h(item.modules.length ? item.modules.join(' ') : 'No ModuleScript is required by this file.')]])}
      <h2 id="related">Related documentation</h2>
      <ul>${item.related.map((id) => { const target = pages.find((entry) => entry.id === id); return `<li>${route(id, target ? h(target.title) : h(id))}</li>`; }).join('')}</ul>
    `;
  };

  for (const item of scripts) {
    pages.push(page(`script/${item.id}`, item.name, 'Code reference', item.summary,
      [item.path, item.name, item.place, item.runtime, item.kind, ...item.functions, item.state, ...item.services, ...item.objects, ...item.events.flat(), ...item.modules, ...item.terms],
      () => scriptBody(item)));
  }

  const navigation = [
    { label: 'Getting started', ids: ['overview', 'repository'] },
    { label: 'Architecture', ids: ['architecture', 'data-flow', 'events'] },
    { label: 'Simulation', ids: ['simulation/signal', 'simulation/frequency', 'simulation/materials', 'simulation/heatmap', 'simulation/antennas', 'terminology'] },
    { label: 'Experiences', ids: ['experience/material-lab', 'experience/small-town', 'interface'] },
    { label: 'Reference', ids: ['code-reference', 'configuration', 'developer-guide'] }
  ];

  window.DOCS_DATA = { pages, scripts, events, navigation, h };
})();
