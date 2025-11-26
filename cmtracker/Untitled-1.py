cmtracker="test.csv"
convert_birthdate="bash /mnt/c/github/fifa/date/dateloan.sh id $birthdate" "2002-02-14T00:00:00.000Z" (dateloan.sh marche au format DD/MM/YYYY)
ABBR_TO_CODE = {
    "GK": 0, "SW"=1 "RWB": 2, "RWF": 2, "RB": 3, "RCB"=4 "CB": 5, "LCB"=6
    "LB": 7, "LWB": 8, "LWF": 8, "RDM"=9 "CDM": 10, "LDM"=11  "RM": 12 "RCM"=13"CM": 14,
    "LCM"=15 "LM": 16, "RAM"=17 "CAM": 18, "LAM":19 "RF"=20 "CF": 21, 'LF'=22 "RS"=24 "ST": 25, "LS"=26
    "CF/SS": 21, "RW": 23, "LW": 27,
}
read -r attributes.acceleration attributes.sprintspeed attributes.agility attributes.balance attributes.jumping attributes.stamina \
attributes.strength attributes.reactions attributes.aggression _ attributes.interceptions attributes.positioning \
attributes.vision attributes.ballcontrol attributes.crossing attributes.dribbling attributes.finishing attributes.freekickaccuracy \
attributes.headingaccuracy attributes.longpassing attributes.shortpassing attributes.marking attributes.shotpower attributes.longshots \
attributes.standingtackle attributes.slidingtackle attributes.volleys attributes.curve attributes.penalties \
attributes.gkdiving attributes.gkhandling  attributes.gkkicking attributes.gkreflexes attributes.gkpositioning \
_ _ _ _ _ _ _ \
info.contract.jointeamdate info.contract.enddate info.contract.isloanedout info.nation.id info.nation.name info.name.firstname info.name.lastname \
info.name.playerjerseyname info.name.knownas info.name.firstnameid info.name.lastnameid info.name.playerjerseynameid info.playerid info.total_attributes \
info.overallrating info.potential info.birthdate _ info.teams.club_team.id info.teams.club_team.name info.teams.club_team.leagueid \
_ _ _ info.teams.club_team.jerseynumber _\
_ info.haircolor info.eyecolor info.skintone info.headtype info.bodytype info.preferredfoot info.skillmoves _ info.internationalrep \
_ _ info.height info.weight _ _ _ info.real_face \
info.isretiring _ _ _ _ _ _ _ _ \
_ _ _ _ _ _ primary_position other_positions \
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _





