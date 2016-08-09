/*
Filename:        fish_c_main.nss
System:          SM's Fishing System (configuration script)
Author:          Michael A. Sinclair (Squatting Monk) <squattingmonk@gmail.com>
Date Created:    Aug. 2, 2015
Summary:
Fishing System configuration settings. This script contains user-definable
toggles and settings for the Fishing System.

This script is freely editable by the mod builder. All below constants may be
overridden, but do not alter the names of the constants or functions.

This script is consumed by fish_t_equipment as an include directive.

Revision Info should only be included for post-release revisions.
-----------------
Revision Date:
Revision Author:
Revision Summary:

*/

#include "fish_i_main"

// -----------------------------------------------------------------------------
//                                  Constants
// -----------------------------------------------------------------------------

// If this is true, fishing will generate debug calls. This may be useful for
// tracking down errors in any of the config functions.
const int FISH_DEBUG_MODE = TRUE;

// This is the maximum distance, in meters, that a PC may be from a fishing spot
// to fish using any equipment. You may further refine this distance for various
// equipment types in the OnFishingStart() config functions below.
const float FISH_MAX_DISTANCE = 10.0f;

// This prefix is added to any fish name to form the resref for that fish. This
// will allow you to follow a good resref naming scheme while still keeping the
// config functions below readable.
const string FISH_ITEM_PREFIX = "fish_";


// ----- Equipment Bait Settings -----------------------------------------------

// The following settings change how different types of fishing equipment use
// bait. If the PC uses fishing equipment not in any of these lists, it defaults
// to ignoring the bait.
//
// You can add baits to a fish's list using AddFishBaits() in the
// OnFishingSetup() config function below. This function takes a comma-separated
// list of fish and and bait, making it easy to add many baits to many fish. The
// function also allows you to add a modifier to the chances a fish will bite
// when the PC is using that bait. This allows fish to prefer different baits.
//
// You can create your own types of fishing equipment: simply give your item a
// "Cast Spell: OnActivate (Self Only)" item property with unlimited uses and
// set its tag to "fish_t_equipment_X", where X is the type of equipment your
// item is. This will be the value you should use to refer to your equipment
// type in the settings and config functions below.
//
// You can create your own types of bait, too: simply give your item a "Cast
// Spell: OnActivate (Self Only)" item property with a single use and set its
// tag to "fish_t_equipment_bait_X", where X is the type of bait your item is.
// This will be the value you should use to refer to your bait type in the
// config functions below.

// This is a comma-separated list of fishing equipment that requires bait to
// function. If the PC uses one of these items but does not have bait, he will
// be unable to fish. If he does use bait, he will only be able to catch fish
// which have the bait in their list. If you don't wish to require the use of
// bait for any item, set this to "".
const string FISH_BAIT_REQUIRED = "pole";

// This is a comma-separated list of fishing equipment for which bait is
// optional. If the PC uses one of these items, he will be able to catch any
// fish regardless of whether the bait is in its list. However, if he has bait
// associated with a fish, the nibble check will be modified accordingly.
const string FISH_BAIT_OPTIONAL = "trap";

// This is a comma-separated list of fishing equipment for which bait is ignored.
// If the PC one of these items, he will be unable to use bait on it. He may
// still use the equipment to catch any fish, regardless of whether the bait is
// in its list. Since the equipment cannot be baited, it will not have any bait
// modifiers to the nibble check.
const string FISH_BAIT_IGNORED = "spear, net";

// This setting is the default handling of bait for items not in the above lists.
// Possible values:
// - FISH_BAIT_IS_IGNORED (default)
// - FISH_BAIT_IS_OPTIONAL
// - FISH_BAIT_IS_REQUIRED
const int FISH_BAIT_DEFAULT = FISH_BAIT_IS_IGNORED;


// ----- Text Strings ----------------------------------------------------------

// This is a list of text strings that may be displayed to the PC by the system
// functions. If you wish to alter or translate these, you may do so here.
const string FISH_TEXT_NO_SPOT      = "This doesn't look like a good place to fish.";
const string FISH_TEXT_NO_BAIT      = "You have no bait! Use a bait item before trying to fish.";
const string FISH_TEXT_NO_EQUIPMENT = "You can't use bait with your currently equipped item!";
const string FISH_TEXT_USE_BAIT     = "You apply the bait to your equipment.";


// -----------------------------------------------------------------------------
//                                 Extensions
// -----------------------------------------------------------------------------

// If you need to add any additional includes, constants, or functions to extend
// the config functions below, you may do so here.


// -----------------------------------------------------------------------------
//                              Config Functions
// -----------------------------------------------------------------------------

// The following are configurable functions that hook into the main fishing
// routine when a fishing equipment item is used. You may change anything inside
// of the functions, but do not change the function names.

// This is a configurable function you can use to alter the fish, environments,
// and baits used in your module. All of the following code will run the first
// time a fishing item is used in your module.
void OnFishingSetup()
{
    // ----- Environment Definitions -------------------------------------------

    InheritFish("lake, river, pond", "freshwater");

    AddFishEnvironments("trout, bass", "freshwater", 20);
    AddFishEnvironments("trout", "pond, river", 30);

    // ----- Bait Definitions --------------------------------------------------

    InheritFish("minnow, worm, insect", "live bait");

    AddFishBaits("trout, bass", "live bait");
    AddFishBaits("trout", "insect", 10);
    AddFishBaits("bass", "minnow", 10);

    // ----- Equipment Definitions ---------------------------------------------

    InheritFish("cane_pole, willow_rod", "pole");

    AddFishEquipment("trout", "pole");

    // ----- Event Messages-----------------------------------------------------

    AddFishingMessage(FISH_EVENT_START,  "pole", "You cast your line. Now to wait...");
    AddFishingMessage(FISH_EVENT_NIBBLE, "pole", "You feel a tug on your line!");
    AddFishingMessage(FISH_EVENT_NIBBLE, "pole", "Something took your bait!");

    AddFishingMessage(FISH_EVENT_START,  "spear", "You ready your spear, eyes intent on the water...");
    AddFishingMessage(FISH_EVENT_NIBBLE, "spear", "There's a fish!");
    AddFishingMessage(FISH_EVENT_NIBBLE, "spear", "You spy a $fish!");
}

// This is a configurable function that runs when the PC uses fishing equipment.
// Returns whether the PC is able to fish. Example uses include setting a max
// distance to the fishing spot based on his equipment, providing flavor text
// about the cast, adding additional restrictions for fishing, or setting a time
// limit between fish bites.
// - OBJECT_SELF: the PC fishing
int OnFishingStart()
{
    // Let's figure out how close the PC needs to be to the fishing spot, given
    // his choice of equipment: fishing pole = 10m, all others = 3m.
    object oSpot = GetFishingSpot();
    string sType = GetFishingEquipmentType();

    if (!GetInheritsFish(sType, "pole") && GetDistanceBetween(OBJECT_SELF, oSpot) > 3.0f)
    {
        ActionFloatingTextString(FISH_TEXT_NO_SPOT);
        return FALSE;
    }

    string sMessage = GetFishingMessage(FISH_EVENT_NIBBLE, GetFishingEquipmentType());
    ActionFloatingTextString(sMessage);

    return TRUE;
}

// This is a configurable function that allows you to modify the chances a type
// of fish will bite. Example uses include making fish more or less likely to
// bite at different times of day or month, modifying chances based on the
// weather, or keeping a type of fish from biting if it's been "fished out" of
// the spot.
// - OBJECT_SELF: the PC attempting to catch the fish.
// - sFish: the resref of the fish whose chances to bite we're testing.
// Returns: an amount to add to the chance the fish will bite.
int OnFishNibble(string sFish)
{
    return 0;
}

// This is a configurable function to handle what happens when the PC fails to
// get a fish to nibble on the line. Example uses include notifying the PC of
// his failure, adding a chance of losing his bait, or having him catch seaweed
// or an old boot instead.
// - OBJECT_SELF: the PC who failed to catch a fish.
void OnFishNibbleFail()
{
    ActionFloatingTextString("You failed to catch anything. Better luck next time!");
}

// This is a configurable function to handle what happens when a PC gets a fish
// on the line. Returns whether the PC is successful at catching the fish.
// Example uses include giving flavor text about the fish's struggle, requiring
// an ability check to catch it, or setting the fishing spot as unavailable for
// a time.
// - OBJECT_SELF: the PC fishing.
// - sFish: the resref of the fish the PC has on the line.
int OnFishNibbleSuccess(string sFish)
{
    return TRUE;
}

// This is a configurable function to intercept the actual creation of the fish.
// Returns whether the system should create the fish. Example uses include
// removing the PC's bait, copying a fish from a container rather than creating
// one from a blueprint (to save on palette items), increasing a persistently
// stored fishing skill, or even just giving the player some XP.
int OnFishCatch(string sFish)
{
    return TRUE;
}

// This is a configurable function to handle the animations for different stages
// of the fishing. nEvent is the fishing event which is currently playing:
// FISH_EVENT_START: plays when fishing begins (after OnFishingStart())
// FISH_EVENT_NIBBLE: plays when a fish has passed the nibble check
// FISH_EVENT_CATCH: plays when a PC successfully catches a fish
// FISH_EVENT_NO_CATCH: plays when a fish nibbled but was not caught
// FISH_EVENT_NO_NIBBLE: plays when no fish nibbled at all
void PlayFishingAnimation(int nEvent)
{
    switch (nEvent)
    {
        case FISH_EVENT_START:
            // Face the fishing spot.
            SetFacingPoint(GetPosition(GetFishingSpot()));

            // Play splash sfx
            PlaySound("as_na_splash1");
            ActionPlayAnimation(ANIMATION_LOOPING_LISTEN, 1.0, 3.0);
            break;

        case FISH_EVENT_NIBBLE:
            ActionWait(1.0f);
            ActionPlayAnimation(ANIMATION_LOOPING_SPASM, 0.1, 6.0);
            ActionPlayAnimation(ANIMATION_FIREFORGET_SALUTE);
            ActionWait(1.0f);
            break;

        case FISH_EVENT_CATCH:
            PlaySound("as_na_splash2");
            ActionPlayAnimation(ANIMATION_FIREFORGET_VICTORY1);
            break;

        case FISH_EVENT_NO_CATCH:
            PlaySound("as_na_splash2");
            ActionPlayAnimation(ANIMATION_FIREFORGET_TAUNT);
            break;

        case FISH_EVENT_NO_NIBBLE:
            ActionPlayAnimation(ANIMATION_FIREFORGET_PAUSE_BORED);
            break;

    }
}


// -----------------------------------------------------------------------------
//                             Extension Functions
// -----------------------------------------------------------------------------

/*
// These functions are examples of extensions that may be made to the system.
// You may include these in the config functions below or write your own.

// This version of OnFishNibble() requires the PC to pass an ability check to
// catch the fish.
int OnFishNibble(string sFish)
{
    FloatingTextStringOnCreature("You feel a tug on your line!", OBJECT_SELF, FALSE);

    // Make the PC pass a strength or dexterity check to catch the fish. This
    // example assumes that SetFishInt() has been called on sFish during the
    // OnFishingSetup() function.
    int nDC, nMod;
    string sMessage;
    if (Random(2))
    {
        nDC  = GetFishInt("STRENGTH", sFish);
        nMod = GetAbilityModifier(ABILITY_STRENGTH);
        sMessage = "You wrestle with the pole as the fish tries to escape!"
    }
    else
    {
        nDC  = GetFishInt("DEXTERITY", sFish);
        nMod = GetAbilityModifier(ABILITY_DEXTERITY);
        sMessage = "The fish jumps wildly, trying to dislodge the hook from its mouth!"
    }

    ActionWait(3.0f);
    ActionDoCommand(FloatingTextStringOnCreature(sMessage, OBJECT_SELF, FALSE));
    ActionDoCommand(PlaySound("as_na_splash1"));
    ActionWait(1.5f);

    // Do the actual roll and notify the PC of the results.
    int nRoll = d20();
    int bSuccess = (nRoll + nMod) >= nDC;
    string sMsg = "Fishing roll: " + IntToString(nRoll) + " + " + IntToString(nMod) +
                  " = " + IntToString(nRoll + nModifier) + " vs. DC: " + IntToString(nDC) +
                  (bSuccess ? " (SUCCESS)" : " (FAILURE)");
    sMsg = StringToRGBString(sMsg, "007");
    ActionDoCommand(SendMessageToPC(OBJECT_SELF, sMsg));
    ActionWait(1.5f);

    // Notify the PC of his success or failure.
    sMsg = (bSuccess ? "You caught the fish!" : "Looks like he got away. Bummer!");
    ActionDoCommand(FloatingTextStringOnCreature(sMsg, OBJECT_SELF, FALSE));
    return bSuccess;
}

int DoFishingCheck(int nDC, int nModifier = 0, int bShowRoll = FALSE)
{
    int nRoll = d20();
    int bSuccess = (nRoll + nModifier) >= nDC;
    if (bShowRoll)
    {
        string sMsg = "Fishing roll: " + IntToString(nRoll) + " + " +
                      IntToString(nModifier) + " = " + IntToString(nRoll + nModifier) +
                      " vs. DC " + IntToString(nDC) + (bSuccess ? " (SUCCESS!)" : " (FAILURE)");
        sMsg = StringToRGBString(sMsg, "007");
        SendMessageToPC(OBJECT_SELF, sMsg);
    }

    return bSuccess;
}

// This is an example extension of the fishing system. The f
int DoFishContests(string sFish)
{
    // Now we do our ability checks. Get the data for this fish...
    int nAbility, nModifier, nDC, nRoll, nDiff, bSuccess, bContinue;
    int nStr = GetLocalInt(FISH_DATA, sFish + "_STR");
    int nDex = GetLocalInt(FISH_DATA, sFish + "_DEX");
    int nCon = GetLocalInt(FISH_DATA, sFish + "_CON");
    string sAbility, sMessage;

    // Loop until we're done with checks.
    do
    {
        // Choose a random ability and do the pre-contest check
        nAbility = Random(3);
        nModifier = OnFishContest(nAbility, sFish) + GetAbilityModifier(nAbility);

        if (nAbility == ABILITY_STRENGTH)
        {
            nDC = nStr;
            sAbility = "Strength";
        }
        else if (nAbility == ABILITY_DEXTERITY)
        {
            nDC = nDex;
            sAbility = "Dexterity";
        }
        else
        {
            nDC = nCon;
            sAbility = "Constitution";
        }

        nRoll = d20();
        nDiff = nRoll + nModifier - nDC;
        bSuccess = nDiff >= 0;
        sMessage = sAbility + " roll: " + IntToString(nRoll) + " + " + IntToString(nModifier) +
                   " = " + IntToString(nRoll + nModifier) + " vs. DC: " + IntToString(nDC) +
                   " (" + (nDiff > 0 ? "SUCCESS)" : "FAILURE)");
        SendMessageToPC(OBJECT_SELF, StringToRGBString(sMessage, "447"));

        // Run our function depending on whether we succeeded.
        bContinue = (bSuccess ? OnFishContestSuccess(nAbility, nDiff, sFish)
                              : OnFishContestFail(nAbility, abs(nDiff), sFish));
    } while (bContinue);

    // If we succeeded on our last check, create the fish.
    return bSuccess;
}

// This is a configurable function you can use to alter the ability checks a PC
// makes against a fish. Example uses: adding the PC's level to the check, or
// adding a persistently stored fishing skill.
// - OBJECT_SELF: the PC performing the check
// - nAbility: the type of check occurring (STR, DEX, or CON).
// - sFish: the resref of the fish the PC has on the line.
// Returns: an amount to add to the ability check.
int OnFishContest(int nAbility, string sFish)
{
    return 0;
}

// This is a configurable function to handle what happens when a PC fails an
// ability check against a fish. Example uses include losing his bait, the
// fishing rod breaking, or even flavorfully telling the PC he lost his catch.
// - OBJECT_SELF: the PC performing the check
// - nAbility: the type of check occurring (STR, DEX, or CON).
// - nDifference: the amount by which the PC failed the check.
// - sFish: the resref of the fish the PC has on the line.
// Returns: whether to perform another ability contest. If returning FALSE, the
// PC will have to try again if he wants another fish,
int OnFishContestFail(int nAbility, int nDifference, string sFish)
{
    FloatingTextStringOnCreature("The fish got away!", OBJECT_SELF, FALSE);
    return FALSE;
}

// This is a configurable function to handle what happens when a PC succeeds on
// an ability check against a fish. Example uses giving him some XP, increasing
// a persistent fishing skill, or even flavorfully telling the PC he caught the
// fish.
// - OBJECT_SELF: the PC performing the check
// - nAbility: the type of check occurring (STR, DEX, or CON).
// - nDifference: the amount by which the PC succeeded the check.
// - sFish: the resref of the fish oPC has on the line.
// Returns: whether to perform another ability contest. If returning FALSE, the
// fish will be created in the PC's inventory.
int OnFishContestSuccess(int nAbility, int nDifference, string sFish)
{
    if (Random(2)) return TRUE;

    FloatingTextStringOnCreature("You caught a fish!", OBJECT_SELF, FALSE);
    return FALSE;
}

*/