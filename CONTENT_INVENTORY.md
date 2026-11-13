# Inventario verificable

Generado por `python3 tool/build_content.py`; el validador comprueba referencias y desenlaces.

| Identificador | Categoría | Dependencias | Desenlaces / efectos |
|---|---|---|---|
| granary_mold | needs | {"resource_max": {"food": 160}} | accept: {'type': 'health', 'value': 6}; decline: {'type': 'resource', 'value': -24, 'resource': 'food'} |
| dry_well | needs | {"resource_max": {"water": 100}} | accept: {'type': 'resource', 'value': 30, 'resource': 'water'}; decline: {'type': 'health', 'value': -7} |
| cold_roofs | needs | {"minPopulation": 20} | accept: {'type': 'health', 'value': 5}; decline: {'type': 'morale', 'value': -9} |
| shared_pot | needs | {"resource_min": {"food": 30}} | accept: {'type': 'morale', 'value': 9}; decline: {'type': 'health', 'value': -3} |
| tainted_cups | needs | {"maxHealth": 90} | accept: {'type': 'health', 'value': 10}; decline: {'type': 'health', 'value': -12} |
| orphan_apprentices | needs | {"minHousing": 0} | accept: {'type': 'resource', 'value': 12, 'resource': 'knowledge'}; decline: {'type': 'morale', 'value': -4} |
| harvest_injury | needs | {"minPopulation": 15} | accept: {'type': 'health', 'value': 7}; decline: {'type': 'population', 'value': -1} |
| fiber_blankets | needs | {"resource_min": {"textiles": 12}} | accept: {'type': 'health', 'value': 5}; decline: {'type': 'morale', 'value': -6} |
| ration_dispute | needs | {"resource_max": {"food": 70}} | accept: {'type': 'morale', 'value': 8}; decline: {'type': 'morale', 'value': -12} |
| clinic_shift | needs | {"maxHealth": 85} | accept: {'type': 'health', 'value': 9}; decline: {'type': 'health', 'value': -5} |
| crowded_homes | needs | {"minPopulation": 35} | accept: {'type': 'housing', 'value': 8}; decline: {'type': 'health', 'value': -6} |
| funeral_garden | needs | {"minDay": 360} | accept: {'type': 'morale', 'value': 12}; decline: {'type': 'morale', 'value': -5} |
| bridge_meeting | relations | {"minPopulation": 10} | accept: {'type': 'relation', 'value': 12}; decline: {'type': 'relation', 'value': -5} |
| borrowed_tools | relations | {"resource_min": {"tools": 6}} | accept: {'type': 'relation', 'value': 10}; decline: {'type': 'relation', 'value': -4} |
| insulted_banner | relations | {"maxMorale": 80} | accept: {'type': 'relation', 'value': 8}; decline: {'type': 'relation', 'value': -12} |
| wedding_delegation | relations | {"resource_min": {"food": 40}} | accept: {'type': 'relation', 'value': 14}; decline: {'type': 'morale', 'value': -3} |
| border_spring | relations | {"resource_max": {"water": 120}} | accept: {'type': 'relation', 'value': 16}; decline: {'type': 'relation', 'value': -16} |
| returned_child | relations | {"resource_min": {"wood": 10}} | accept: {'type': 'relation', 'value': 9}; decline: {'type': 'morale', 'value': -4} |
| guest_healer | relations | {"resource_min": {"medicine": 4}} | accept: {'type': 'resource', 'value': 18, 'resource': 'knowledge'}; decline: {'type': 'relation', 'value': -6} |
| broken_promise | relations | {"resource_min": {"metal": 8}} | accept: {'type': 'relation', 'value': 10}; decline: {'type': 'relation', 'value': -15} |
| river_festival | relations | {"resource_min": {"food": 60}} | accept: {'type': 'relation', 'value': 18}; decline: {'type': 'morale', 'value': -3} |
| refugee_letter | relations | {"minHousing": 3} | accept: {'type': 'population', 'value': 5}; decline: {'type': 'relation', 'value': -8} |
| envoy_detained | relations | {"maxMorale": 90} | accept: {'type': 'relation', 'value': 11}; decline: {'type': 'relation', 'value': -18} |
| joint_maps | relations | {"resource_min": {"knowledge": 10}} | accept: {'type': 'relation', 'value': 14}; decline: {'type': 'resource', 'value': -3, 'resource': 'knowledge'} |
| buried_cart | exploration | {"minDay": 10} | accept: {'type': 'resource', 'value': 18, 'resource': 'metal'}; decline: {'type': 'resource', 'value': 3, 'resource': 'knowledge'} |
| glowing_moss | exploration | {"minDay": 30} | accept: {'type': 'resource', 'value': 20, 'resource': 'knowledge'}; decline: {'type': 'health', 'value': -5} |
| sealed_library | exploration | {"resource_min": {"tools": 5}} | accept: {'type': 'resource', 'value': 35, 'resource': 'knowledge'}; decline: {'type': 'resource', 'value': 8, 'resource': 'stone'} |
| old_battery | exploration | {"minDay": 40} | accept: {'type': 'resource', 'value': 25, 'resource': 'energy'}; decline: {'type': 'health', 'value': -6} |
| herd_tracks | exploration | {"resource_min": {"food": 20}} | accept: {'type': 'resource', 'value': 25, 'resource': 'food'}; decline: {'type': 'resource', 'value': 5, 'resource': 'knowledge'} |
| ravine_rope | exploration | {"resource_min": {"textiles": 9}} | accept: {'type': 'resource', 'value': 2, 'resource': 'crystal'}; decline: {'type': 'resource', 'value': 4, 'resource': 'knowledge'} |
| salt_cave | exploration | {"resource_min": {"wood": 15}} | accept: {'type': 'resource', 'value': 30, 'resource': 'food'}; decline: {'type': 'resource', 'value': 6, 'resource': 'stone'} |
| sunken_station | exploration | {"resource_min": {"fuel": 9}} | accept: {'type': 'resource', 'value': 28, 'resource': 'knowledge'}; decline: {'type': 'resource', 'value': 4, 'resource': 'metal'} |
| watchtower_echo | exploration | {"minDay": 60} | accept: {'type': 'resource', 'value': 15, 'resource': 'knowledge'}; decline: {'type': 'morale', 'value': -2} |
| orchard_ruins | exploration | {"resource_min": {"tools": 4}} | accept: {'type': 'resource', 'value': 35, 'resource': 'food'}; decline: {'type': 'resource', 'value': 10, 'resource': 'wood'} |
| marked_stones | exploration | {"minDay": 20} | accept: {'type': 'resource', 'value': 22, 'resource': 'knowledge'}; decline: {'type': 'resource', 'value': 5, 'resource': 'stone'} |
| buried_machines | exploration | {"resource_min": {"wood": 16}} | accept: {'type': 'resource', 'value': 12, 'resource': 'tools'}; decline: {'type': 'resource', 'value': 8, 'resource': 'metal'} |
| wagon_axle | economy | {"resource_min": {"metal": 6}} | accept: {'type': 'relation', 'value': 8}; decline: {'type': 'resource', 'value': -8, 'resource': 'food'} |
| grain_offer | economy | {"resource_max": {"food": 150}} | accept: {'type': 'resource', 'value': 45, 'resource': 'food'}; decline: {'type': 'relation', 'value': -2} |
| tool_standard | economy | {"resource_min": {"metal": 14}} | accept: {'type': 'resource', 'value': 16, 'resource': 'tools'}; decline: {'type': 'resource', 'value': 3, 'resource': 'knowledge'} |
| fuel_spill | economy | {"resource_min": {"fuel": 5}} | accept: {'type': 'health', 'value': 7}; decline: {'type': 'environment', 'value': 10} |
| storage_labels | economy | {"minPopulation": 20} | accept: {'type': 'resource', 'value': 12, 'resource': 'food'}; decline: {'type': 'morale', 'value': -3} |
| counterfeit_relic | economy | {"resource_min": {"energy": 5}} | accept: {'type': 'resource', 'value': 10, 'resource': 'knowledge'}; decline: {'type': 'resource', 'value': -5, 'resource': 'metal'} |
| flooded_quarry | economy | {"resource_max": {"stone": 100}} | accept: {'type': 'resource', 'value': 25, 'resource': 'stone'}; decline: {'type': 'resource', 'value': -8, 'resource': 'stone'} |
| loom_cooperative | economy | {"resource_min": {"wood": 16}} | accept: {'type': 'resource', 'value': 28, 'resource': 'textiles'}; decline: {'type': 'morale', 'value': -4} |
| caravan_guarantee | economy | {"resource_min": {"food": 50}} | accept: {'type': 'resource', 'value': 14, 'resource': 'metal'}; decline: {'type': 'relation', 'value': -5} |
| scrap_sorting | economy | {"resource_min": {"tools": 4}} | accept: {'type': 'resource', 'value': 22, 'resource': 'metal'}; decline: {'type': 'environment', 'value': 3} |
| empty_stalls | economy | {"maxMorale": 75} | accept: {'type': 'relation', 'value': 9}; decline: {'type': 'morale', 'value': -7} |
| water_contract | economy | {"resource_min": {"water": 80}} | accept: {'type': 'resource', 'value': 16, 'resource': 'metal'}; decline: {'type': 'relation', 'value': -3} |
| open_council | politics | {"minPopulation": 25} | accept: {'type': 'morale', 'value': 12}; decline: {'type': 'morale', 'value': -9} |
| guard_petition | politics | {"minDay": 60} | accept: {'type': 'defense', 'value': 12}; decline: {'type': 'morale', 'value': -6} |
| succession_notes | politics | {"minDay": 720} | accept: {'type': 'morale', 'value': 8}; decline: {'type': 'resource', 'value': -6, 'resource': 'knowledge'} |
| ration_records | politics | {"resource_max": {"food": 120}} | accept: {'type': 'morale', 'value': 10}; decline: {'type': 'morale', 'value': -12} |
| quiet_dissent | politics | {"maxMorale": 75} | accept: {'type': 'morale', 'value': 13}; decline: {'type': 'resource', 'value': -5, 'resource': 'tools'} |
| archive_access | politics | {"resource_min": {"knowledge": 20}} | accept: {'type': 'relation', 'value': 7}; decline: {'type': 'morale', 'value': -8} |
| land_registry | politics | {"minPopulation": 35} | accept: {'type': 'morale', 'value': 11}; decline: {'type': 'relation', 'value': -8} |
| night_patrol | politics | {"maxMorale": 85} | accept: {'type': 'defense', 'value': 8}; decline: {'type': 'morale', 'value': -10} |
| public_work | politics | {"resource_min": {"stone": 22}} | accept: {'type': 'morale', 'value': 15}; decline: {'type': 'relation', 'value': -5} |
| old_debt | politics | {"minDay": 360} | accept: {'type': 'morale', 'value': 9}; decline: {'type': 'morale', 'value': -11} |
| school_vote | politics | {"resource_min": {"knowledge": 15}} | accept: {'type': 'resource', 'value': 22, 'resource': 'knowledge'}; decline: {'type': 'morale', 'value': -5} |
| emergency_powers | politics | {"maxHealth": 70} | accept: {'type': 'morale', 'value': 14}; decline: {'type': 'defense', 'value': 8} |
| coil_test | technology | {"resource_min": {"metal": 10}} | accept: {'type': 'resource', 'value': 24, 'resource': 'knowledge'}; decline: {'type': 'resource', 'value': 5, 'resource': 'energy'} |
| sterile_room | technology | {"maxHealth": 90} | accept: {'type': 'health', 'value': 12}; decline: {'type': 'resource', 'value': -4, 'resource': 'medicine'} |
| seed_selection | technology | {"resource_min": {"food": 60}} | accept: {'type': 'resource', 'value': 18, 'resource': 'knowledge'}; decline: {'type': 'resource', 'value': 8, 'resource': 'food'} |
| radio_noise | technology | {"resource_min": {"energy": 10}} | accept: {'type': 'relation', 'value': 8}; decline: {'type': 'resource', 'value': 5, 'resource': 'knowledge'} |
| metal_fatigue | technology | {"resource_min": {"tools": 5}} | accept: {'type': 'resource', 'value': 20, 'resource': 'knowledge'}; decline: {'type': 'resource', 'value': -8, 'resource': 'metal'} |
| river_turbine | technology | {"resource_min": {"wood": 24}} | accept: {'type': 'resource', 'value': 25, 'resource': 'energy'}; decline: {'type': 'environment', 'value': 6} |
| lens_polish | technology | {"resource_min": {"stone": 15}} | accept: {'type': 'resource', 'value': 26, 'resource': 'knowledge'}; decline: {'type': 'resource', 'value': 1, 'resource': 'crystal'} |
| culture_vat | technology | {"resource_min": {"knowledge": 80}} | accept: {'type': 'resource', 'value': 16, 'resource': 'medicine'}; decline: {'type': 'health', 'value': -4} |
| servitor_trial | technology | {"resource_min": {"metal": 20}} | accept: {'type': 'resource', 'value': 20, 'resource': 'tools'}; decline: {'type': 'resource', 'value': 8, 'resource': 'energy'} |
| heat_recovery | technology | {"resource_min": {"fuel": 8}} | accept: {'type': 'health', 'value': 8}; decline: {'type': 'resource', 'value': -5, 'resource': 'fuel'} |
| memory_crystal | technology | {"resource_min": {"knowledge": 40}} | accept: {'type': 'resource', 'value': 35, 'resource': 'knowledge'}; decline: {'type': 'resource', 'value': 1, 'resource': 'crystal'} |
| quiet_reactor | technology | {"resource_min": {"tools": 12}} | accept: {'type': 'resource', 'value': 45, 'resource': 'energy'}; decline: {'type': 'health', 'value': -10} |
| stolen_crates | conflict | {"resource_min": {"food": 35}} | accept: {'type': 'relation', 'value': 10}; decline: {'type': 'defense', 'value': -6} |
| border_patrol | conflict | {"minPopulation": 25} | accept: {'type': 'defense', 'value': 10}; decline: {'type': 'relation', 'value': -10} |
| deserter_gate | conflict | {"minHousing": 3} | accept: {'type': 'population', 'value': 4}; decline: {'type': 'relation', 'value': -12} |
| supply_siege | conflict | {"resource_min": {"water": 40}} | accept: {'type': 'defense', 'value': 12}; decline: {'type': 'resource', 'value': -15, 'resource': 'food'} |
| watch_fire | conflict | {"resource_min": {"wood": 20}} | accept: {'type': 'defense', 'value': 14}; decline: {'type': 'resource', 'value': -8, 'resource': 'metal'} |
| armistice_cost | conflict | {"maxRelation": 0} | accept: {'type': 'relation', 'value': 18}; decline: {'type': 'population', 'value': -2} |
| damaged_wall | conflict | {"resource_min": {"stone": 24}} | accept: {'type': 'defense', 'value': 18}; decline: {'type': 'defense', 'value': -10} |
| missing_scout | conflict | {"minPopulation": 15} | accept: {'type': 'morale', 'value': 8}; decline: {'type': 'population', 'value': -1} |
| captured_wagon | conflict | {"resource_min": {"metal": 15}} | accept: {'type': 'relation', 'value': 9}; decline: {'type': 'population', 'value': -2} |
| militia_drill | conflict | {"resource_min": {"food": 50}} | accept: {'type': 'defense', 'value': 15}; decline: {'type': 'morale', 'value': -5} |
| burial_truce | conflict | {"maxRelation": 10} | accept: {'type': 'relation', 'value': 20}; decline: {'type': 'morale', 'value': -9} |
| weapon_cache | conflict | {"minDay": 120} | accept: {'type': 'defense', 'value': 22}; decline: {'type': 'resource', 'value': 18, 'resource': 'metal'} |
| river_silt | environment | {"resource_max": {"water": 150}} | accept: {'type': 'resource', 'value': 24, 'resource': 'food'}; decline: {'type': 'resource', 'value': -15, 'resource': 'water'} |
| young_forest | environment | {"minDay": 90} | accept: {'type': 'environment', 'value': -12}; decline: {'type': 'resource', 'value': 20, 'resource': 'wood'} |
| locust_cloud | environment | {"resource_min": {"food": 40}} | accept: {'type': 'resource', 'value': 18, 'resource': 'food'}; decline: {'type': 'resource', 'value': -30, 'resource': 'food'} |
| landslide_signs | environment | {"resource_min": {"stone": 22}} | accept: {'type': 'environment', 'value': -10}; decline: {'type': 'housing', 'value': -6} |
| ash_sky | environment | {"minDay": 180} | accept: {'type': 'health', 'value': 8}; decline: {'type': 'health', 'value': -10} |
| wildfire_break | environment | {"resource_min": {"wood": 35}} | accept: {'type': 'environment', 'value': -9}; decline: {'type': 'resource', 'value': -30, 'resource': 'wood'} |
| fish_return | environment | {"resource_min": {"food": 35}} | accept: {'type': 'environment', 'value': -15}; decline: {'type': 'resource', 'value': 28, 'resource': 'food'} |
| toxic_pool | environment | {"resource_min": {"stone": 20}} | accept: {'type': 'health', 'value': 10}; decline: {'type': 'environment', 'value': 18} |
| dust_masks | environment | {"maxHealth": 90} | accept: {'type': 'health', 'value': 12}; decline: {'type': 'health', 'value': -14} |
| seed_bank | environment | {"resource_min": {"food": 70}} | accept: {'type': 'environment', 'value': -10}; decline: {'type': 'resource', 'value': 8, 'resource': 'knowledge'} |
| winter_water | environment | {"resource_max": {"water": 100}} | accept: {'type': 'resource', 'value': 25, 'resource': 'water'}; decline: {'type': 'resource', 'value': -20, 'resource': 'water'} |
| earth_tremor | environment | {"minPopulation": 20} | accept: {'type': 'housing', 'value': 10}; decline: {'type': 'health', 'value': -12} |
| canal_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'canal_cooperation'} → canal_cooperation; control: {'type': 'flag', 'value': 'canal_control'} → canal_pressure |
| canal_cooperation | technology | {"flags": ["canal_cooperation"]} | finish: {'type': 'morale', 'value': 3} → canal_legacy; abandon: {'type': 'relation', 'value': -8} → canal_fracture |
| canal_pressure | technology | {"flags": ["canal_control"]} | reform: {'type': 'relation', 'value': 6} → canal_legacy; enforce: {'type': 'defense', 'value': 5} → canal_fracture |
| canal_legacy | technology | {} | record: {'type': 'resource', 'value': 65, 'resource': 'food'}, {'type': 'flag', 'value': 'canal_legacy'} |
| canal_fracture | technology | {} | face: {'type': 'relation', 'value': -20}, {'type': 'flag', 'value': 'canal_fracture'} |
| fever_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'fever_cooperation'} → fever_cooperation; control: {'type': 'flag', 'value': 'fever_control'} → fever_pressure |
| fever_cooperation | technology | {"flags": ["fever_cooperation"]} | finish: {'type': 'morale', 'value': 3} → fever_legacy; abandon: {'type': 'relation', 'value': -8} → fever_fracture |
| fever_pressure | technology | {"flags": ["fever_control"]} | reform: {'type': 'relation', 'value': 6} → fever_legacy; enforce: {'type': 'defense', 'value': 5} → fever_fracture |
| fever_legacy | technology | {} | record: {'type': 'health', 'value': 25}, {'type': 'flag', 'value': 'fever_legacy'} |
| fever_fracture | technology | {} | face: {'type': 'population', 'value': -7}, {'type': 'flag', 'value': 'fever_fracture'} |
| machine_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'machine_cooperation'} → machine_cooperation; control: {'type': 'flag', 'value': 'machine_control'} → machine_pressure |
| machine_cooperation | technology | {"flags": ["machine_cooperation"]} | finish: {'type': 'morale', 'value': 3} → machine_legacy; abandon: {'type': 'relation', 'value': -8} → machine_fracture |
| machine_pressure | technology | {"flags": ["machine_control"]} | reform: {'type': 'relation', 'value': 6} → machine_legacy; enforce: {'type': 'defense', 'value': 5} → machine_fracture |
| machine_legacy | technology | {} | record: {'type': 'resource', 'value': 90, 'resource': 'metal'}, {'type': 'flag', 'value': 'machine_legacy'} |
| machine_fracture | technology | {} | face: {'type': 'housing', 'value': -12}, {'type': 'flag', 'value': 'machine_fracture'} |
| seed_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'seed_cooperation'} → seed_cooperation; control: {'type': 'flag', 'value': 'seed_control'} → seed_pressure |
| seed_cooperation | technology | {"flags": ["seed_cooperation"]} | finish: {'type': 'morale', 'value': 3} → seed_legacy; abandon: {'type': 'relation', 'value': -8} → seed_fracture |
| seed_pressure | technology | {"flags": ["seed_control"]} | reform: {'type': 'relation', 'value': 6} → seed_legacy; enforce: {'type': 'defense', 'value': 5} → seed_fracture |
| seed_legacy | technology | {} | record: {'type': 'resource', 'value': 100, 'resource': 'food'}, {'type': 'flag', 'value': 'seed_legacy'} |
| seed_fracture | technology | {} | face: {'type': 'environment', 'value': 30}, {'type': 'flag', 'value': 'seed_fracture'} |
| comet_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'comet_cooperation'} → comet_cooperation; control: {'type': 'flag', 'value': 'comet_control'} → comet_pressure |
| comet_cooperation | technology | {"flags": ["comet_cooperation"]} | finish: {'type': 'morale', 'value': 3} → comet_legacy; abandon: {'type': 'relation', 'value': -8} → comet_fracture |
| comet_pressure | technology | {"flags": ["comet_control"]} | reform: {'type': 'relation', 'value': 6} → comet_legacy; enforce: {'type': 'defense', 'value': 5} → comet_fracture |
| comet_legacy | technology | {} | record: {'type': 'housing', 'value': 20}, {'type': 'flag', 'value': 'comet_legacy'} |
| comet_fracture | technology | {} | face: {'type': 'population', 'value': -12}, {'type': 'flag', 'value': 'comet_fracture'} |
| council_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'council_cooperation'} → council_cooperation; control: {'type': 'flag', 'value': 'council_control'} → council_pressure |
| council_cooperation | technology | {"flags": ["council_cooperation"]} | finish: {'type': 'morale', 'value': 3} → council_legacy; abandon: {'type': 'relation', 'value': -8} → council_fracture |
| council_pressure | technology | {"flags": ["council_control"]} | reform: {'type': 'relation', 'value': 6} → council_legacy; enforce: {'type': 'defense', 'value': 5} → council_fracture |
| council_legacy | technology | {} | record: {'type': 'morale', 'value': 25}, {'type': 'flag', 'value': 'council_legacy'} |
| council_fracture | technology | {} | face: {'type': 'relation', 'value': -25}, {'type': 'flag', 'value': 'council_fracture'} |
| aquifer_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'aquifer_cooperation'} → aquifer_cooperation; control: {'type': 'flag', 'value': 'aquifer_control'} → aquifer_pressure |
| aquifer_cooperation | technology | {"flags": ["aquifer_cooperation"]} | finish: {'type': 'morale', 'value': 3} → aquifer_legacy; abandon: {'type': 'relation', 'value': -8} → aquifer_fracture |
| aquifer_pressure | technology | {"flags": ["aquifer_control"]} | reform: {'type': 'relation', 'value': 6} → aquifer_legacy; enforce: {'type': 'defense', 'value': 5} → aquifer_fracture |
| aquifer_legacy | technology | {} | record: {'type': 'resource', 'value': 150, 'resource': 'water'}, {'type': 'flag', 'value': 'aquifer_legacy'} |
| aquifer_fracture | technology | {} | face: {'type': 'relation', 'value': -30}, {'type': 'flag', 'value': 'aquifer_fracture'} |
| visitors_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'visitors_cooperation'} → visitors_cooperation; control: {'type': 'flag', 'value': 'visitors_control'} → visitors_pressure |
| visitors_cooperation | technology | {"flags": ["visitors_cooperation"]} | finish: {'type': 'morale', 'value': 3} → visitors_legacy; abandon: {'type': 'relation', 'value': -8} → visitors_fracture |
| visitors_pressure | technology | {"flags": ["visitors_control"]} | reform: {'type': 'relation', 'value': 6} → visitors_legacy; enforce: {'type': 'defense', 'value': 5} → visitors_fracture |
| visitors_legacy | technology | {} | record: {'type': 'resource', 'value': 100, 'resource': 'knowledge'}, {'type': 'flag', 'value': 'visitors_legacy'} |
| visitors_fracture | technology | {} | face: {'type': 'morale', 'value': -25}, {'type': 'flag', 'value': 'visitors_fracture'} |
| caravan_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'caravan_cooperation'} → caravan_cooperation; control: {'type': 'flag', 'value': 'caravan_control'} → caravan_pressure |
| caravan_cooperation | technology | {"flags": ["caravan_cooperation"]} | finish: {'type': 'morale', 'value': 3} → caravan_legacy; abandon: {'type': 'relation', 'value': -8} → caravan_fracture |
| caravan_pressure | technology | {"flags": ["caravan_control"]} | reform: {'type': 'relation', 'value': 6} → caravan_legacy; enforce: {'type': 'defense', 'value': 5} → caravan_fracture |
| caravan_legacy | technology | {} | record: {'type': 'resource', 'value': 70, 'resource': 'metal'}, {'type': 'flag', 'value': 'caravan_legacy'} |
| caravan_fracture | technology | {} | face: {'type': 'relation', 'value': -24}, {'type': 'flag', 'value': 'caravan_fracture'} |
| heirs_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'heirs_cooperation'} → heirs_cooperation; control: {'type': 'flag', 'value': 'heirs_control'} → heirs_pressure |
| heirs_cooperation | technology | {"flags": ["heirs_cooperation"]} | finish: {'type': 'morale', 'value': 3} → heirs_legacy; abandon: {'type': 'relation', 'value': -8} → heirs_fracture |
| heirs_pressure | technology | {"flags": ["heirs_control"]} | reform: {'type': 'relation', 'value': 6} → heirs_legacy; enforce: {'type': 'defense', 'value': 5} → heirs_fracture |
| heirs_legacy | technology | {} | record: {'type': 'resource', 'value': 80, 'resource': 'knowledge'}, {'type': 'flag', 'value': 'heirs_legacy'} |
| heirs_fracture | technology | {} | face: {'type': 'morale', 'value': -18}, {'type': 'flag', 'value': 'heirs_fracture'} |
| island_opening | technology | {"minDay": 90} | cooperate: {'type': 'flag', 'value': 'island_cooperation'} → island_cooperation; control: {'type': 'flag', 'value': 'island_control'} → island_pressure |
| island_cooperation | technology | {"flags": ["island_cooperation"]} | finish: {'type': 'morale', 'value': 3} → island_legacy; abandon: {'type': 'relation', 'value': -8} → island_fracture |
| island_pressure | technology | {"flags": ["island_control"]} | reform: {'type': 'relation', 'value': 6} → island_legacy; enforce: {'type': 'defense', 'value': 5} → island_fracture |
| island_legacy | technology | {} | record: {'type': 'relation', 'value': 35}, {'type': 'flag', 'value': 'island_legacy'} |
| island_fracture | technology | {} | face: {'type': 'population', 'value': -8}, {'type': 'flag', 'value': 'island_fracture'} |
| facility_found | exploration | {"minDay": 3, "facilityFound": true, "flagsMissing": ["facility_committed"]} | seal: {'type': 'flag', 'value': 'facility_closed'} → facility_sealed; dismantle: {'type': 'flag', 'value': 'facility_dismantled'} → facility_salvage; share: {'type': 'flag', 'value': 'facility_shared'} → facility_shared; study: {'type': 'flag', 'value': 'facility_studied'} → facility_study |
| facility_sealed | exploration | {"flags": ["facility_closed"]} | record: {'type': 'environment', 'value': -8}, {'type': 'morale', 'value': 6}, {'type': 'flag', 'value': 'facility_safe'} |
| facility_salvage | exploration | {"flags": ["facility_dismantled"]} | reuse: {'type': 'resource', 'value': 60, 'resource': 'metal'}, {'type': 'resource', 'value': 15, 'resource': 'tools'}, {'type': 'flag', 'value': 'facility_scrapped'} |
| facility_shared | exploration | {"flags": ["facility_shared"]} | pact: {'type': 'relation', 'value': 30}, {'type': 'resource', 'value': 45, 'resource': 'knowledge'}, {'type': 'flag', 'value': 'facility_pact'} |
| facility_study | exploration | {"flags": ["facility_studied"]} | local: {'type': 'health', 'value': -3} → facility_energy; signal: {'type': 'resource', 'value': 15, 'resource': 'knowledge'} → facility_contact |
| facility_energy | exploration | {} | integrate: {'type': 'resource', 'value': 100, 'resource': 'energy'}, {'type': 'population', 'value': 6}, {'type': 'flag', 'value': 'facility_power'} |
| facility_contact | exploration | {} | listen: {'type': 'resource', 'value': 60, 'resource': 'knowledge'}, {'type': 'flag', 'value': 'contact_signal'} → visitors_opening; disconnect: {'type': 'resource', 'value': 35, 'resource': 'energy'}, {'type': 'flag', 'value': 'contact_refused'} |
