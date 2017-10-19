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
	private var m_exportButtonClip: MovieClip;
	private var m_closeButtonClip: MovieClip;
	
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
		//data += "[gear]\nhead=%head%\nfinger=%finger%\nwrist=%wrist%\nneck=%neck%\nluck=%luck%\nwaist=%waist%\nocult=%ocult%\n" +
		//"primary=%primary%\nsecundary=%secundary%\n";
		
		// need to scrape tooltips for information
		// https://github.com/Xeio/FastCaches/blob/master/src/com/xeio/FastCaches/FastCaches.as <- shows how to access tooltip data
		// Xeio: M_decriptions is an array, I imagine you'd need to loop if for a complicated item
		
		/* this won't work		
		var inventory: Inventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer,
			Character.GetClientCharID().GetInstance()));
		var item: InventoryItem = undefined;
		var itemString: String = "";
		
		item = inventory.GetItemAt(_global.Enums.ItemEquipLocation.e_Chakra_1);
		itemString = item.m_Name + ", ";
		itemString = item.m_Rarity + ":" item.m_Rank + ", ";
		itemString = item.m_GlyphRarity + ":" m_GlyphRank + ", ";
		itemString = item.m_SignetRarity + ":" m_SignetRank;

		data.replace("%head%", itemString); // head 
		*/
			// finger
			// wrist
			// luck
			// waist
			// ocult
			// primary
			// secondary
			
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
		// Creates a window and shows it with the content
		Dbg("Starting to create a window");
		m_exportWindowClip = m_swfRoot.createEmptyMovieClip("CharExportClip", m_swfRoot.getNextHighestDepth());
		

		// Draw a semi-transparent rectangle
		m_exportWindowClip.lineStyle(3, 0xFFFFFF, 75);
		m_exportWindowClip.beginFill(0x000000, 100);
		m_exportWindowClip.moveTo(50, 50);
		m_exportWindowClip.lineTo(500, 50);
		m_exportWindowClip.lineTo(500, 500);
		m_exportWindowClip.lineTo(50, 500);
		m_exportWindowClip.lineTo(50, 50);
		m_exportWindowClip.endFill();
		
		// Hookup some callbacks to provide dragging functionality - flash does most of the hard work for us
		m_exportWindowClip.onPress = Delegate.create(this, function() { this.m_exportWindowClip.startDrag(); } );
		m_exportWindowClip.onRelease = Delegate.create(this, function() { this.m_exportWindowClip.stopDrag(); } );
		
		// Create a textfield on our coloured box
		var statText: TextField = m_exportWindowClip.createTextField("BoxText", m_exportWindowClip.getNextHighestDepth(), 50, 50, 450, 450);
		statText.embedFonts = false;
		statText.selectable = true;
		statText.wordWrap = true;
		
		// Specify some style information for this text
		var format: TextFormat = new TextFormat("src.assets.fonts.FuturaMDBk.ttf", 14, 0xFFFFFF); // , false, false, false); 
		format.align = "left";
		
		statText.setNewTextFormat(format);	// Apply this style to all new text
		statText.setTextFormat(format); // Apply this style to all existing text
		
		// Finally, specify some text
		statText.text = content;
		
		/*
		statText.selectionBeginIndex = 0;
		statText.selectionEndIndex = statText.text.length;
		
		System.setClipboard(content);
		// Create Close and Copy Buttons
		m_closeButtonClip = new Button();
		m_exportButtonClip = new Button();
		m_exportWindowClip.attachMovie(m_closeButtonClip, "closeButton", m_exportWindowClip.getNextHighestDepth());
		m_exportButtonClip.attachMovie(m_exportButtonClip, "exportButton", m_exportWindowClip.getNextHighestDepth());
		*/
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

	public static function Dbg(message: String): Void
	{
		var date: Date = new Date();
		Log.Warning(String(date.getTime()) + "CharExport_debug>", message);
	}
}
