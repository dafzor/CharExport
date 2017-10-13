import mx.utils.Delegate;
import com.Utils.Archive;
import com.GameInterface.Log;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.SpellBase;

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
		var stats = GetCharacterStats();

		if (DistributedValue.GetDValue("CharExport_Export") == true) {
			ShowExportWindow(stats);
		}
		else {
			CloseExportWindow();
		}
		
	}

	public function GetCharacterStats(): String
	{
		// extract character stats
		Dbg("Starting to get character stats");
		var player: Character = Character.GetClientCharacter();
		var stats: String = "";
		
		//stats += "Character: " + player.GetName() + "\n";

		// Debug hunt for where the stats are stored
		stats += "Stats:\n";
		
		stats += "glance reduction = " + player.GetStat(_global.Enums.SkillType.e_skill_GlanceReduction) + "\n";
		
		for (var key: String in _global.Enums.Stat) {
			//stats += String(Character.GetClientCharacter().GetStat(Number(key))) + "\n";
		}

		stats += "skillType:\n";
		for (var key: String in _global.Enums.SkillType) {
			stats += key + "\n";
		}
		
		
		stats += "passives:\n";
		for (var i = 0; i < 5; i++) {
			var spellID = SpellBase.GetPassiveAbility(i);
			if (spellID.valueOf() != 0) {
				Dbg(String(spellID) + "=" + SpellBase.GetSpellData(spellID).m_Name);
				stats += SpellBase.GetSpellData(spellID).m_Name + "\n";
			}
			
		}
		return stats;
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