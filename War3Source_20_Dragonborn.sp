//////////////////////////////////////
// 			T F 2   O N L Y         //
//////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include "W3SIncs/War3Source_Interface"  
#include "W3SIncs/War3Source_Effects"

new thisRaceID;
public Plugin:myinfo = 
{
	name = "Race - Dragonborn",
	author = "Smilax",
	description = "The Dragonborn race for War3Source.",
	version = "2.0.0.0",
	url = "http://cgaclan.com/"
};

new SKILL_ROAR,SKILL_SCALES,SKILL_DRAGONBORN,ULTIMATE_DRAGONBREATH;
/*
Roar - Stuns targets in a radius and applys the scare effect.
Scales - Gives you a small armor bonus, &  at level 4 makes you invunerable to ultimates due to your magic scales.
Dragonborn - You get increased health from being dragonborn.
Dragonbreath - Breathe fire in an area infront of you.

To Do:
Roar - Finished except for effect		|Fear effect
Dragonborn - Finished					|No effects
Scales - Finished						|No effects
Ultimate - Unfinished
Effects - Unfinished
IT'S ALL FINISHED

V. 2.0.0.0
Changed max hp to ability immunitys because tf2 max hp is dumb.

Cool things learned this race:
**W3PrintSkillDmgConsole(i,client,War3_GetWar3DamageDealt(),SKILL_NAME);
**if (TF2_GetClass(client) == TFClass_Scout) etc etc
**new const SkillColor[4] = {255, 255, 255, 155} changing skill colors via array, neato.
**That max health in tf2 is stupid.
*/
new RoarRadius[5]={0,200,450,700,950};
new Float:RoarCooldownTime=25.0;
new Float:ScalesMagic[5]={0.0,1.0,2.0,3.0,4.0};
new Float:ScalesPhysical[5]={0.0,2.0,4.0,6.0,8.0}; 
new Float:dragvec[3]={0.0,0.0,0.0};
new Float:victimvec[3]={0.0,0.0,0.0};
new Float:DragonBreathRange[5]={0.0,400.0,600.0,800.0,1000.0};

// Sounds
new String:roarsound[]="war3source/dragonborn/roar.mp3";
new String:ultsndblue[]="war3source/dragonborn/ultblue.mp3";
new String:ultsndred[]="war3source/dragonborn/ultred.mp3";

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Dragonborn","Dragonborn");
	SKILL_ROAR=War3_AddRaceSkill(thisRaceID,"Roar","Puts all those around you in a 200/450/700/950 radius in a fear state for a 1.5 duration. +Ability",false,4);
	SKILL_SCALES=War3_AddRaceSkill(thisRaceID,"Scales","Gives you a high physical resistance. 2/4/6/8 physical 1/2/3/4 magic armor. Passive",false,4);
	SKILL_DRAGONBORN=War3_AddRaceSkill(thisRaceID,"Dragonborn","Being dragonborn gives immunitys to certain magics. immunity to wards/skills/slows/ultimates",false,4);
	ULTIMATE_DRAGONBREATH=War3_AddRaceSkill(thisRaceID,"Dragons Breath","Blue Team - 10 second jarate effect | Red Team - set player on fire for 10 seconds. Level increases range +Ultimate",true,4); 
	War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
}

public OnPluginStart()
{
CreateTimer(0.5,FootstepTimer,_,TIMER_REPEAT); //The footstep effect

}

public OnMapStart()
{
War3_PrecacheParticle("explosion_trailSmoke");//ultimate trail
War3_PrecacheParticle("burningplayer_flyingbits"); //Red Team foot effect
War3_PrecacheParticle("water_bulletsplash01"); //Blue Team foot effect
War3_PrecacheParticle("waterfall_bottomwaves"); //Blue Team DragonsBreath Effect
War3_PrecacheParticle("explosion_trailFire");//Red Team DragonsBreath Effect
War3_PrecacheParticle("yikes_text");//Roar Effect Victim
War3_PrecacheParticle("particle_nemesis_burst_red");//Red Team Roar Caster
War3_PrecacheParticle("particle_nemesis_burst_blue");//Blue Team Roar Caster
War3_PrecacheSound(roarsound);
War3_PrecacheSound(ultsndblue);
War3_PrecacheSound(ultsndred);
}

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULTIMATE_DRAGONBREATH);
		if(ult_level>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_DRAGONBREATH,true))
			{
				new Float:breathrange= DragonBreathRange[ult_level];
				//War3_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION);
				new target = War3_GetTargetInViewCone(client,breathrange,false,23.0,DragonFilter);
				//new Float:duration = DarkorbDuration[ult_level];
				if(target>0)
				{
					if(GetClientTeam(client) == TEAM_RED)
					{
						EmitSoundToAll(ultsndred,client);
						GetClientAbsOrigin(target,victimvec);
						TF2_IgnitePlayer(target, target);
						ThrowAwayParticle("explosion_trailFire", victimvec, 1.0);
						AttachThrowAwayParticle(target, "explosion_trailSmoke", victimvec, "", 10.0);
						War3_CooldownMGR(client,25.0,thisRaceID,ULTIMATE_DRAGONBREATH,_,_);
						W3Hint(target,HINT_COOLDOWN_NOTREADY,5.0,"A dragon set you aflame");
					}
					if(GetClientTeam(client) == TEAM_BLUE)
					{
						EmitSoundToAll(ultsndblue,client);
						EmitSoundToAll(ultsndblue,client);
						GetClientAbsOrigin(target,victimvec);
						TF2_AddCondition(target, TFCond_Jarated, 10.0);
						AttachThrowAwayParticle(target, "waterfall_bottomwaves", victimvec, "", 2.0);
						War3_CooldownMGR(client,25.0,thisRaceID,ULTIMATE_DRAGONBREATH,_,_);
						W3Hint(target,HINT_COOLDOWN_NOTREADY,5.0,"A dragon weakend you with waterbreath");
					}
					//PrintHintText(target,"%T","You have been blinded by a Dark Elf!",target);
					//PrintHintText(client,"%T","You have blinded someone!",client);
				}
			}
		}	
	}			
}

public bool:DragonFilter(client)
{
	return (!W3HasImmunity(client,Immunity_Ultimates));
}

public Action:FootstepTimer(Handle:timer,any:client) //footsy flame/water effects only on ground yay!
{
	for(new client=1; client <= MaxClients; client++)
	{
		if(ValidPlayer(client, true))
		{
			if(War3_GetRace(client) == thisRaceID)
			{
				GetClientAbsOrigin(client,dragvec);
				//dragvec[2]+=35.0;  Crotch Level lololol Firecrotch 
				dragvec[2]+=15;
				if(GetClientTeam(client) == TEAM_BLUE)
				{
					//New Hint text to use. W3Hint(client,HINT_COOLDOWN_NOTREADY,5.0,"BUTTSANDWOIUADHAL;KJDA;LKFJAL;SDFJ;LASDKFJKL;ASDFJKL;ASDFJKL;");
					AttachThrowAwayParticle(client, "water_bulletsplash01", dragvec, "", 1.5);
				}
				if(GetClientTeam(client) == TEAM_RED)
				{
					AttachThrowAwayParticle(client, "burningplayer_flyingbits", dragvec, "", 1.5);
				}
			}
		}
	}
}

//Roar - If it's too overpowered I might add in an adrenaline effect to all clients effect afterward (Increased speed during thirdperson stun animation)
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_ROAR,true))
		{
			new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_ROAR);
			if(skilllvl > 0)
			{
				new Float:AttackerPos[3];
				GetClientAbsOrigin(client,AttackerPos);
				new AttackerTeam = GetClientTeam(client);
				new Float:VictimPos[3];
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true))
					{
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(AttackerPos,VictimPos)<RoarRadius[skilllvl])
						{
							if(GetClientTeam(i)!=AttackerTeam&&!W3HasImmunity(client,Immunity_Ultimates))
							{
								//TF2_StunPlayer(client, Float:duration, Float:slowdown=0.0, stunflags, attacker=0);
								EmitSoundToAll(roarsound,client);
								EmitSoundToAll(roarsound,client);
								TF2_StunPlayer(i, 1.0, _, TF_STUNFLAGS_GHOSTSCARE,0);
								War3_CooldownMGR(client,RoarCooldownTime,thisRaceID,SKILL_ROAR,_,_);
								GetClientAbsOrigin(client,dragvec);
								dragvec[2]+=70;
								if(GetClientTeam(client) == TEAM_RED)
								{
									AttachThrowAwayParticle(client, "particle_nemesis_burst_red", dragvec, "", 1.5);
									W3Hint(i,HINT_COOLDOWN_NOTREADY,1.5,"OH GOD A DRAGON");
								}
								if(GetClientTeam(client) == TEAM_BLUE)
								{
									AttachThrowAwayParticle(client, "particle_nemesis_burst_blue", dragvec, "", 1.5);
									W3Hint(i,HINT_COOLDOWN_NOTREADY,1.5,"OH GOD A DRAGON");
								}
							}
						}
					}
				}
			}
		}
	}
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_armor=War3_GetSkillLevel(client,thisRaceID,SKILL_SCALES);
		new magicarmor=ScalesMagic[skilllevel_armor];
		new physicalarmor=ScalesPhysical[skilllevel_armor];
		War3_SetBuff(client,fArmorMagic,thisRaceID,magicarmor);
		War3_SetBuff(client,fArmorPhysical,thisRaceID,physicalarmor);
		new skilllvl = War3_GetSkillLevel(client,thisRaceID,SKILL_DRAGONBORN);
		if (skilllvl > 0)
		{
			War3_SetBuff(client,bImmunityWards,thisRaceID,1);
			if (skilllvl > 1)
			{
				War3_SetBuff(client,bImmunitySkills,thisRaceID,1);
				if (skilllvl >2)
				{
					War3_SetBuff(client,bSlowImmunity,thisRaceID,1);
					if (skilllvl >3)
					{
						War3_SetBuff(client,bImmunityUltimates,thisRaceID,1);
					}
				}
			}
		}	
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fArmorMagic,thisRaceID,0);
		War3_SetBuff(client,fArmorPhysical,thisRaceID,0);
		War3_SetBuff(client,bImmunityWards,thisRaceID,0);
		War3_SetBuff(client,bImmunitySkills,thisRaceID,0);
		War3_SetBuff(client,bSlowImmunity,thisRaceID,0);
		War3_SetBuff(client,bImmunityUltimates,thisRaceID,0);
	}
	else
	{	
		if(IsPlayerAlive(client)){
			InitPassiveSkills(client);
			
		}	
	}
}