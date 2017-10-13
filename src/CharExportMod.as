import mx.utils.Delegate;
import com.Utils.Archive;
import com.GameInterface.Log;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.SpellBase;
import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;

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
	private var m_doExport: DistributedValue;

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
		var stats = GetCharacterData();

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
		var data: String = "[character]\nname=%name%\nlevel=%level%\n" +
		"[stats]\nhp=%hp%\nhit=%hit%\ncrit=%crit%\npower=%power%\nglance=%glance%\ndefence=%defence%\nprotection=%protection%\n" +
		"[gear]\nhead=%head%\nfinger=%finger%\nwrist=%wrist%\nneck=%neck%\nluck=%luck%\nwaist=%waist%\nocult=%ocult%\n" +
		"primary=%primary%\nsecundary=%secundary%\n" + "[skills]\npassives=%passives%";

		var player: Character = Character.GetClientCharacter();
		
		// character
		data.replace("%name%", player.GetName()); // name
		// level

		// stats
			// hp
			// hit
			// crit
			// power
			// glance
			// defence
			// protection

		// Debug hunt for where the stats are stored
		data.replace("%glance%", player.GetStat(_global.Enums.SkillType.e_skill_GlanceReduction));

		/*		
		for (var key: String in _global.Enums.Stat) {
			//stats += String(Character.GetClientCharacter().GetStat(Number(key))) + "\n";
		}
		for (var key: String in _global.Enums.SkillType) {
			//stats += key + "\n";
		}
		*/

		// gear (name, quality:level, glyph:value, signet:value)

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
		data.replace("%passives%", passives);

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
		
		// Specify some style information for this text
		var format: TextFormat = new TextFormat("src.assets.fonts.FuturaMDBk.ttf", 14, 0xFFFFFF); // , false, false, false); 
		format.align = "left";
		
		statText.setNewTextFormat(format);	// Apply this style to all new text
		statText.setTextFormat(format); // Apply this style to all existing text

		// Create Close and Copy Buttons
		// TODO

		// Finally, specify some text
		statText.text = content;
	}

	public function CloseExportWindow(): Void
	{
		m_exportWindowClip.clear();
		m_exportWindowClip.removeMovieClip();
	}

	public static function Dbg(message: String): Void
	{
		var date: Date = new Date();
		Log.Warning(String(date.getTime()) + "CharExport_debug>", message);
	}
}