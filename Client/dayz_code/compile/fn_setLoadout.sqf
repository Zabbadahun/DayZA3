/*

	AUTHOR: aeroson
	NAME: fnc_set_loadout.sqf - Changed to fn_setLoadout.sqf by MistaD
	VERSION: 3.9
	
	DOWNLOAD & PARTICIPATE:
	https://github.com/aeroson/get-set-loadout
	http://forums.bistudio.com/showthread.php?148577-GET-SET-Loadout-(saves-and-loads-pretty-much-everything)
	
	DESCRIPTION:
	These scripts allows you set/get (load/save)all of the unit's gear, including:
	uniform, vest, backpack, contents of it, all quiped items, all three weapons with their attachments, currently loaded magazines and number of ammo in magazines
	Useful for saving/loading loadouts. 
	Ideal for revive scripts where you have to set exactly the same loadout to newly created unit.
	Uses workaround with placeholders to add vest/backpack items, so items stay where you put them.
	
	PARAMETER(S):
	0 : target unit
	1 : array of strings/arrays containing desired target unit's loadout, obtained from fnc_get_loadout.sqf
	2 : (optional) array of options, default [] : ["ammo"]  will allow loading of partially emptied magazines, otherwise magazines will be full 	 	
	
	addAction support:
	Sets player's loadout from global var loadout
  
	Original script go to aeroson
	Tweaks and adjustments go to MistaD
*/

private ["_target","_options","_loadMagsAmmo","_data","_loadedMagazines","_placeholderCount","_add","_outfit","_weapon","_muzzles","_magazines","_magazine","_currentWeapon","_currentMode"];
_source = _this select 3;
diag_log (format["SetLoadout Source: %1", _source]);
_options = [];
_data = [];

// addAction support
if(count _this < 5) then {
	private ["_PARAM_INDEX"]; _PARAM_INDEX=0;
	#define PARAMREQ(A) if (count _this <= _PARAM_INDEX) exitWith { diag_log format["required param '%1' not supplied in file:'%2' at line:%3", #A ,__FILE__,__LINE__]; }; A = _this select _PARAM_INDEX; _PARAM_INDEX=_PARAM_INDEX+1;
	#define PARAM(A,B) A = B; if (count _this > _PARAM_INDEX) then { A = _this select _PARAM_INDEX; }; _PARAM_INDEX=_PARAM_INDEX+1;
	PARAMREQ(_target)
	PARAMREQ(_data)
	PARAM(_options,[])
} else {
	_target = player;
	_data = loadout;
};

if(isNil{_data}) exitWith {
	diag_log "[SYSTEM] Your character data is null!";
};
if(count _data <= 0) exitWith {
	diag_log "[SYSTEM] Your character data is empty!";
};
diag_log(format["Data: %1",_data]);
if(count _data < 13) exitWith {
	diag_log "[SYSTEM] Your character data is corrupted!";
};
_loadMagsAmmo = "ammo" in _options;
_loadedMagazines = [];
if(count _data > 13) then {
	if(typeName(_data select 13)=="ARRAY") then {
		_loadedMagazines = _data select 13;
	};
};

_currentWeapon = "";
if(count _data > 14) then {
	_currentWeapon = _data select 14;
};
_currentMode = ""; 
if(count _data > 15) then {
	_currentMode = _data select 15;
};	

_placeholderCount = 0;

// basic add function intended for use with uniform and vest
_add = {
	private ["_target","_item"];
	_target = _this select 0;
	_item = _this select 1;
	if(typename _item == "ARRAY") then {
		if(_item select 0 != "") then {
			if(_loadMagsAmmo) then {
				_target addMagazine _item;
			} else {
				_target addMagazine (_item select 0);
			};
		};
	} else {
		if(_item != "") then {
			if(isClass(configFile>>"CfgMagazines">>_item)) then {
				_target addMagazine _item;
			} else {
				if(isClass(configFile>>"CfgWeapons">>_item>>"WeaponSlotsInfo") && getNumber(configFile>>"CfgWeapons">>_item>>"showempty")==1 && !(_item in ["NVGoggles","Binoculars","ItemGPS","ItemCompass","ItemMap","ItemWatch"])) then {
					_target addWeapon _item;  
				} else {
					_target addItem _item;
				};
			};
		};
	};
};
// remove clothes to prevent incorrect mag loading
removeUniform _target;
removeVest _target;
removeBackpack _target;

_outfit = "DZ_Patrol_Pack_A3"; // we need to add items somewhere before we can assign them
_target addBackpack _outfit;
//waitUntil { backpack _target == _outfit };

removeAllAssignedItems _target;
// add assigned items
{ 
	[_target,_x] call _add;
	_target assignItem _x;
	diag_log _x;
} forEach (_data select 0);
// add primary weapon, add primary weapon loaded magazine, add primary weapon items
_target removeWeapon (primaryWeapon _target);
_weapon = _data select 1;      
if(_weapon != "") then {
	if(isClass(configFile>>"CfgWeapons">>_weapon)) then {
		if (_currentWeapon == "") then {
			_currentWeapon = _weapon;
		}; 
		if(count _loadedMagazines > 0) then {
			_magazine = _loadedMagazines select 0; // get loaded magazines from saved loadout
			diag_log("P: " + str(_magazine));
		} else {          
			_magazine = getArray(configFile>>"CfgWeapons">>_weapon>>"magazines") select 0; // generate default magazines	
		};        	  
		[_target, _magazine] call _add;						
		_target addWeapon _weapon;                                                                                                                
		{ 
			if(_x!="" && !(_x in (primaryWeaponItems _target))) then { 
				_target addPrimaryWeaponItem _x; 
			}; 
		} foreach (_data select 2);
	} else {
		diag_log format["[SYSTEM] Primary %1 doesn't exist",_weapon];
		if (_currentWeapon == _weapon) then {
			_currentWeapon = "";
			_currentMode = "";
		};
	};                             											                                                                                               
};

// add handgun weapon, add handgun weapon loaded magazine, add handgun weapon items
_target removeWeapon (handgunWeapon _target);
_weapon =_data select 3;
if(_weapon != "") then {
	if(isClass(configFile>>"CfgWeapons">>_weapon)) then {
		if (_currentWeapon == "") then {
			_currentWeapon = _weapon;
		};
		if(count _loadedMagazines > 0) then {
			_magazine = _loadedMagazines select 1;
			diag_log("H: " + str(_magazine));
		} else {   
			_magazine = getArray(configFile>>"CfgWeapons">>_weapon>>"magazines") select 0;
		};
		[_target, _magazine] call _add;	
		_target addWeapon _weapon;
		{ 
			if(_x!="" && !(_x in (handgunItems _target))) then {
				_target addHandgunItem _x; 
			}; 
		} foreach (_data select 4);
	} else {
		diag_log format["[SYSTEM] Handgun %1 doesn't exist",_weapon];
		if (_currentWeapon == _weapon) then {
			_currentWeapon = "";
			_currentMode = "";
		};
	};
};
      
// add secondary weapon, add secondary weapon loaded magazine, add secondary weapon items		                                 
_target removeWeapon (secondaryWeapon _target);
_weapon = _data select 5;
if(_weapon != "") then {
	if(isClass(configFile>>"CfgWeapons">>_weapon)) then {
		if (_currentWeapon == "") then {
			_currentWeapon = _weapon;
		};
		if(count _loadedMagazines > 0) then {
			_magazine = _loadedMagazines select 2;
			diag_log("S: " + str(_magazine));
		} else {
			_magazine = getArray(configFile>>"CfgWeapons">>_weapon>>"magazines") select 0;
		};
		[_target, _magazine] call _add;	
		_target addWeapon _weapon;
		{ 
			if(_x!="" && !(_x in (secondaryWeaponItems _target))) then {
				_target addSecondaryWeaponItem _x;
			}; 
		} foreach (_data select 6);
	} else {
		diag_log format["[SYSTEM] Secondary %1 doesn't exist",_weapon];
		if (_currentWeapon == _weapon) then {
			_currentWeapon = "";
			_currentMode = "";
		};
	};		
};

// select weapon and firing mode
if ( vehicle _target == _target && _currentWeapon != "" && _currentMode != "" ) then {
	_muzzles = 0;                                                                                                           
	while { (_currentWeapon != currentMuzzle _target || _currentMode != currentWeaponMode _target ) && _muzzles < 100 } do {
		_target action ["SWITCHWEAPON", _target, _target, _muzzles];
		_muzzles = _muzzles + 1;
	};
	if(_muzzles >= 100) then {
		diag_log format["[SYSTEM] Mode %1 for %2 doesn't exist", _currentMode, _currentWeapon];
		_currentMode = "";		
	};
} else {
	_currentMode = "";
};
if (_currentMode == "" && _currentWeapon != "") then {
	_target selectWeapon _currentWeapon;
};


// add uniform, add uniform items and fill uniform with placeholders
_outfit = _data select 7;  
if(_outfit != "") then {
	if(isClass(configFile>>"CfgWeapons">>_outfit)) then {
		_target addUniform _outfit;
		_target addItem "ItemWatch";
		if( loadUniform _target > 0 ) then {
			_target removeItem "ItemWatch";
			{ 
				[_target,_x] call _add; 
			} foreach (_data select 8);
			while { true } do {
				_loadBeforeAdd = loadUniform _target;
				_target addItem "ItemWatch";
				if (loadUniform _target == _loadBeforeAdd) exitWith {};
				_placeholderCount = _placeholderCount + 1;
			};	
		};
	} else {
		diag_log format["[SYSTEM] Uniform %1 doesn't exist",_outfit];
	};		
};

// add vest, add vest items and fill vest with placeholders
_outfit = _data select 9; 
if(_outfit != "") then {
	if(isClass(configFile>>"CfgWeapons">>_outfit)) then {
		_target addVest _outfit;
		_target addItem "ItemWatch";
		if( loadVest _target > 0 ) then {
			_target removeItem "ItemWatch";	
			{ 
				[_target,_x] call _add;
			} foreach (_data select 10);
			while { true } do {
				_loadBeforeAdd = loadVest _target;
				_target addItem "ItemWatch";
				if (loadVest _target == _loadBeforeAdd) exitWith {};
				_placeholderCount = _placeholderCount + 1;
			};
		};
	} else {
		diag_log format["[SYSTEM] Vest %1 doesn't exist",_outfit];
	};
};      
// more complex add function intended for use with backpack
_add = {
	private ["_target","_item"];
	_target = _this select 0;
	_item = _this select 1;
	if(typename _item == "ARRAY") then {
		if(_item select 0 != "") then {
			if(_loadMagsAmmo) then {
				_target addMagazine _item;
			} else {
				_target addMagazine (_item select 0);
			};
		};
	} else {
		if(_item != "") then {
			if(getNumber(configFile>>"CfgVehicles">>_item>>"isbackpack")==1) then {
				(unitBackpack _target) addBackpackCargo [_item,1];  
			} else {
				if(isClass(configFile>>"CfgMagazines">>_item)) then {
					_target addMagazine _item;
				} else {
					if(isClass(configFile>>"CfgWeapons">>_item>>"WeaponSlotsInfo") && getNumber(configFile>>"CfgWeapons">>_item>>"showempty")==1) then {
						(unitBackpack _target) addWeaponCargo [_item,1]; 
					} else {
						_target addItem _item;
					};
				};
			};
		};
	};
};
/*
_add = {
	private ["_target","_item"];
	_target = _this select 0;
	_item = _this select 1;
	if(typename _item == "ARRAY") then {
		if(_item select 0 != "") then {
			if(_loadMagsAmmo) then {
				_target addMagazine _item;
			} else {
				_target addMagazine (_item select 0);
			};
		};
	} else {
		if(isClass(configFile>>"CfgMagazines">>_item)) then {
			_target addMagazine _item;
		} else {
			if(_item != "") then {
				if(getNumber(configFile>>"CfgVehicles">>_item>>"isbackpack")==1) then {
					(unitBackpack _target) addBackpackCargo [_item,1];  
				} else {
					if(isClass(configFile>>"CfgWeapons">>_item>>"WeaponSlotsInfo") && getNumber(configFile>>"CfgWeapons">>_item>>"showempty")==1) then {
						(unitBackpack _target) addWeaponCargo [_item,1];  
					} else {
						_target addItem _item;         
					};
				};
			};
		};
	};
};   
*/  


// add backpack and add backpack items
removeBackpack _target;
_outfit = _data select 11; 
if(_outfit != "") then {
	if(getNumber(configFile>>"CfgVehicles">>_outfit>>"isbackpack")==1) then {
		_target addBackpack _outfit;                                                                    
		clearAllItemsFromBackpack _target;
		{
			[_target, _x] call _add;
		} foreach (_data select 12);
	} else {
		diag_log format["[SYSTEM] Backpack %1 doesn't exist",_outfit];
	};
};


// remove placeholders
for "_i" from 1 to _placeholderCount do {
	_target removeItem "ItemWatch"; 
};

if ( vehicle _target == _target ) then {
	//_target switchMove "";
	_target setPos (getPos _target);
};