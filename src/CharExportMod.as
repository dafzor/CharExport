import com.Components.ItemSlot;
import gfx.controls.TextArea;
import mx.utils.Delegate;
import com.Utils.Archive;
import com.GameInterface.Log;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.SpellBase;
import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.Skills;
import com.GameInterface.Game.CharacterBase;

/**
 * This is a Character export mod to allow easy importing of characters
 * into [SWLsimNET](https://github.com/Vadelius/swlsimNET).
 * 
 * @author daf
 */
class CharExportMod
{
	private var m_swfRoot: MovieClip; // Our root MovieClip
	private var m_exportWindowClip: MovieClip;
	private var m_closeButtonClip: MovieClip;
	
	private var m_exportTextField: TextField;
	
	private var m_doExport: DistributedValue;
	private var m_playerCharacter: Character;

    public function CharExportMod(swfRoot: MovieClip)
	{
		// Store a reference to the root MovieClip
		m_swfRoot = swfRoot;
    }
	
	public function OnLoad()
	{
		// creates the DistributedValue to do the action
		m_doExport = DistributedValue.Create("CharExport_Export");
		m_doExport.SetValue(false);
		m_doExport.SignalChanged.Connect(DoExport, this);
		
		m_playerCharacter = Character.GetClientCharacter();
	}
	
	public function OnUnload()
	{
		// clears the distributed value
		m_doExport.SignalChanged.Disconnect(DoExport, this);
		m_doExport = undefined;
	}
	
	public function Activate(config: Archive)
	{		
	}
	
	public function Deactivate(): Archive
	{
		// Some example code for saving variables to an Archive
		var config: Archive = new Archive();
		return config;
	}

	public function DoExport(): Void
	{
		Dbg("DoExport");
		var stats = GetCharacterInfo();
		
		if (DistributedValue.GetDValue("CharExport_Export") == true) {
			ShowExportWindow(stats);
		}
		else {
			CloseExportWindow();
		}
	}

	public function GetCharacterInfo(): String
	{
		// Export string that we'll be using to format our output
		var data: String = "";
		
		// character
		data += "[character]\nname=%name%\nlevel=%level%\n";
		data = data.split("%name%").join(m_playerCharacter.GetName()); // name
		data = data.split("%level%").join(m_playerCharacter.GetStat(_global.Enums.Stat.e_Level, 2)); // level
		
		// stats
		data += "[stats]\nhp=%hp%\ncombat=%combat%\nhealing=%healing%\nhit=%hit%\ncrit=%crit%\ncritpower=%critpower%\nglance=%glance%\n" +
		"defence=%defence%\nprotection=%protection%\n";
		
		data = data.split("%hp%").join(m_playerCharacter.GetStat(_global.Enums.Stat.e_Life, 2)); // hp
		data = data.split("%hit%").join(GetStatValues(_global.Enums.SkillType.e_Skill_GlanceReduction)); // hit
		data = data.split("%combat%").join(GetStatValues(_global.Enums.SkillType.e_Skill_CombatPower)); // combat
		data = data.split("%healing%").join(GetStatValues(_global.Enums.SkillType.e_Skill_HealingPower)); // healing
		data = data.split("%crit%").join(GetStatValues(_global.Enums.SkillType.e_Skill_CriticalChance)); // crit
		data = data.split("%critpower%").join(GetStatValues(_global.Enums.SkillType.e_Skill_CritPower)); // crit power
		data = data.split("%glance%").join(GetStatValues(_global.Enums.SkillType.e_Skill_EvadeChance)); // glance
		data = data.split("%defence%").join(GetStatValues(_global.Enums.SkillType.e_Skill_GlanceChance)); // defence
		data = data.split("%protection%").join(GetStatValues(_global.Enums.SkillType.e_Skill_PhysicalMitigation)); // protection
		
		// gear (name, quality:level, glyph:value, signet:value)
		data += "[gear]\nhead=%head%\nfinger=%finger%\nwrist=%wrist%\nneck=%neck%\nluck=%luck%\nwaist=%waist%\nocult=%ocult%\n" +
		"gadget=%gadget%\nprimary=%primary%\nsecondary=%secondary%\n";
		
		data = data.split("%head%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Chakra_7)); //head
		
		data = data.split("%finger%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Chakra_4)); //finger
		data = data.split("%neck%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Chakra_5)); //neck
		data = data.split("%wrist%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Chakra_6)); //wrist
		
		data = data.split("%luck%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Chakra_1)); //luck
		data = data.split("%ocult%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Chakra_3)); //occult
		data = data.split("%waist%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Chakra_2)); //waist
		
		data = data.split("%gadget%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Aegis_Talisman_1)); //gadget
		data = data.split("%primary%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Wear_First_WeaponSlot)); //primary
		data = data.split("%secondary%").join(GetCharacterItemName(_global.Enums.ItemEquipLocation.e_Wear_Second_WeaponSlot)); //secondary
		
		
		// skills
		data += "[skills]\npassives=%passives%";
			
		// passives
		var passives: String = "";
		for (var i = 0; i < 5; i++) {
			var spellID = SpellBase.GetPassiveAbility(i);

			if (spellID.valueOf() != 0) {
				Dbg(String(spellID) + "=" + SpellBase.GetSpellData(spellID).m_Name);
				passives += SpellBase.GetSpellData(spellID).m_Name + ", ";
			}
		}
		// removes the last ", "
		passives = passives.substr(0, passives.length - 2);
		data = data.split("%passives%").join(passives);

		return data;
	}

	public function ShowExportWindow(content: String): Void
	{
		var width: Number = 500;
		var height: Number = 600;
		var x: Number = 50;
		var y: Number = 50;
		
		// Creates a window and shows it with the content
		Dbg("Starting to create a window");
		m_exportWindowClip = m_swfRoot.createEmptyMovieClip("CharExportClip", m_swfRoot.getNextHighestDepth());
		

		// Draw a semi-transparent rectangle
		m_exportWindowClip.lineStyle(3, 0x000000, 75);
		m_exportWindowClip.beginFill(0x000000, 100);
		m_exportWindowClip.moveTo(x, y);
		m_exportWindowClip.lineTo(x+width, y);
		m_exportWindowClip.lineTo(x+width, y+height);
		m_exportWindowClip.lineTo(x, y+height);
		m_exportWindowClip.lineTo(x, y);
		m_exportWindowClip.endFill();
		m_exportWindowClip._alpha = 75;
		
		
		// Hookup some callbacks to provide dragging functionality - flash does most of the hard work for us
		m_exportWindowClip.onPress = Delegate.create(this, function() { this.m_exportWindowClip.startDrag(); Selection.setFocus(this.m_exportTextField); } );
		m_exportWindowClip.onRelease = Delegate.create(this, function() { this.m_exportWindowClip.stopDrag(); } );
		
		/*
		// Create Close and Copy Buttons
		m_closeButtonClip = new Button();
		m_exportWindowClip.attachMovie(m_closeButtonClip, "closeButton", m_exportWindowClip.getNextHighestDepth());
		*/
		
		// Create a textfield on our window
		m_exportTextField = m_exportWindowClip.createTextField("exportText", m_exportWindowClip.getNextHighestDepth(), x+10, y+10, width-20, height-(10+75));
		m_exportTextField.type = "input";
		m_exportTextField.embedFonts = true;
		m_exportTextField.selectable = true;
		m_exportTextField.wordWrap = true;
		m_exportTextField.border = true;
		m_exportTextField.background = true;
		m_exportTextField.backgroundColor = 0x696969;
		
		m_exportTextField.onSetFocus = function ():Void { Selection.setSelection(0, content.length); }
		
		// Specify some style information for this text
		var format: TextFormat = new TextFormat("src.assets.fonts.FuturaMDBk.ttf", 14, 0xFFFFFF); // , false, false, false); 
		format.align = "left";
		
		m_exportTextField.setNewTextFormat(format);	// Apply this style to all new text
		m_exportTextField.setTextFormat(format); // Apply this style to all existing text
		
		var useMessage: TextField = m_exportWindowClip.createTextField("usageText", m_exportWindowClip.getNextHighestDepth(), x+10, y+height-75, width-20, 40);
		useMessage.wordWrap = true;
		useMessage.setNewTextFormat(format);
		
		useMessage.text = "Use Ctrl+C to copy the content. If you change gear, please close and open the window again to update the export.";
		
		// Finally, specify some text and set focus on it
		m_exportTextField.text = content;
		Selection.setFocus(m_exportTextField);
	}

	public function CloseExportWindow(): Void
	{
		m_exportWindowClip.clear();
		m_exportWindowClip.removeMovieClip();
	}
	
	public function GetStatValues(skill: Number): String
	{
		var values: String = "";
		
		Skills.GetSkill(_global.Enums.SkillType.e_Skill_GlanceReduction, 0);
		
		CharacterBase.SetNextWeaponActive(_global.Enums.ItemEquipLocation.e_Wear_First_WeaponSlot);
		values += Skills.GetSkill(skill, 0) + ":";
		
		CharacterBase.SetNextWeaponActive(_global.Enums.ItemEquipLocation.e_Wear_Second_weaponSlot);
		values += Skills.GetSkill(skill, 0);
		
		return values;
	}
	
	public function GetCharacterItemName(slot: Number): String
	{
		var inventory: Inventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, Character.GetClientCharID().GetInstance()));
		var item: InventoryItem = inventory.GetItemAt(slot);
		
		return item.m_Name;
	}

	public static function Dbg(message: String): Void
	{
		var date: Date = new Date();
		Log.Warning(String(date.getTime()) + "CharExport_debug>", message);
	}
}
