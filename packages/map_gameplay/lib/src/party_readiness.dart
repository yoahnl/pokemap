import 'package:map_core/map_core.dart';

int usablePartyMemberCount(PlayerParty party) =>
    party.members.where((member) => !member.isFainted).length;

bool partyHasAtLeastUsableMembers(PlayerParty party, int minimumCount) =>
    minimumCount >= 1 &&
    minimumCount <= maxPlayerPartySize &&
    usablePartyMemberCount(party) >= minimumCount;
