--!strict

local Types = {}

Types.PlayerRole = {
	Guardian = "Guardian",
	Thief    = "Thief",
}

Types.PlayerState = {
	Lobby      = "Lobby",
	Alive      = "Alive",
	Caught     = "Caught",
	Caged      = "Caged",
	Escaped    = "Escaped",
	Eliminated = "Eliminated",
	OutOfRound = "OutOfRound",
}

-- Round snapshot shape (GetRoundSnapshot / SnapshotService / RuntimeAuditService)
export type RoundSnapshotPayload = {
	roundId            : number,
	roundState         : string,
	roundActive        : boolean,
	timeRemaining      : number,
	totalThiefCount    : number,
	activePlayersCount : number,
	guardianName       : string?,
	winner             : string?,
	reason             : string?,
	resultsFired       : boolean,
}

-- Per-player row inside RoundResults payload
export type PlayerScoreRow = {
	userId      : number,
	name        : string,
	role        : string,
	totalScore  : number,
	stats       : { [string]: any },
	heroMoment  : string?,
}

-- RoundResults remote payload (RoundScoreService.FireResults)
export type ResultsPayload = {
	winner             : string?,
	reason             : string?,
	mvp                : PlayerScoreRow?,
	players            : { PlayerScoreRow },
	heroMoments        : { { title: string, playerName: string?, value: any? } },
	teamSummary        : {
		thiefTotalScore    : number,
		guardianTotalScore : number,
		sealsCompleted     : number,
		rescuesCompleted   : number,
		idolExtracted      : boolean,
	},
	nextRoundSeconds   : number,
}

return Types
