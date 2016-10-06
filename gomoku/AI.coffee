do ->
	CHESS_NONE = ''
	CHESS_BLACK = ''
	CHESS_WHITE = ''
	BOARD_LENGTH = ''
	WIN_COUNT = 5
	startTime = 0
	chessBoard = []
	# response in 3 seconds
	timesUp = 1000 * 1000

	class Move
		constructor: (@x, @y, @score = 0) ->

	class Player
		setName: (@name) ->
		toString: ->
			return "Player: #{@name}"

	class AIPlayer extends Player
		depth = 4
		score = - 1
		minX = 999
		minY = 999
		maxX = - 1
		maxY = - 1
		blackMoves = []
		whiteMoves = []
		chessNum = 0
		bestMove = ''
		startUpMove = ''
		myTurn = 1
		constructor: (gameTurn) ->
			depth = 4
			score = - 1
			minX = 999
			minY = 999
			maxX = - 1
			maxY = - 1
			blackMoves = []
			whiteMoves = []
			chessNum = 0
			bestMove = ''
			startUpMove = ''
			myTurn = 1
			GAME_CONFIG = window.GAME_CONFIG
			CHESS_NONE = GAME_CONFIG.CHESS_NONE
			CHESS_BLACK = GAME_CONFIG.CHESS_BLACK
			CHESS_WHITE = GAME_CONFIG.CHESS_WHITE
			BOARD_LENGTH = GAME_CONFIG.BOARD_LENGTH
			WIN_COUNT = GAME_CONFIG.WIN_COUNT
			startUpMove = new StartUpMove()
			myTurn = gameTurn
			for i in [0...BOARD_LENGTH]
				chessBoard[i] = []
				for j in [0...BOARD_LENGTH]
					chessBoard[i][j] = CHESS_NONE
		
		getMove: (lastMove) ->
			startTime = new Date().getTime()
			if not lastMove or lastMove.length < 2
				myTurn = 0
			else
				# myTurn = 1
				update lastMove[0], lastMove[1], 1 - myTurn
				chessNum++
			bestMove = startUpMove.getNextMove myTurn, chessNum, lastMove
			if bestMove
				update bestMove.x, bestMove.y, myTurn
				chessNum++
				return [bestMove.x, bestMove.y]
			bestMove = getNextMove lastMove
			console.log 'getMove takes', (new Date().getTime() - startTime)/1000
			chessNum++
			return [bestMove.x, bestMove.y]

		update = (x, y, currentTurn)->
			updateMN x, y
			chessBoard[x][y] = currentTurn
			return

		getNextMove = (lastMove) ->
			ts = new Date().getTime()
			score = evaluate()
			console.log 'evaluate takes', (new Date().getTime() - ts)/1000
			ts = new Date().getTime()
			initMoves()
			console.log 'initMoves takes', (new Date().getTime() - ts)/1000
			ts = new Date().getTime()
			alphaBeta depth, -999999999, 999999999, myTurn
			console.log 'alphaBeta takes', (new Date().getTime() - ts)/1000
			updateScoreWithBestMove()
			return bestMove

		updateScoreWithBestMove = ->
			x = bestMove.x
			y = bestMove.y
			updateMN x, y
			chessBoard[x][y] = myTurn
			score = -1
			return

		updateMN = (x, y) ->
			minX = x if x < minX
			maxX = x if x > maxX
			minY = y if y < minY
			maxY = y if y > maxY
			return

		isWin = (candidate) ->
			aRs = genAnalysisResult candidate.x, candidate.y
			for aResult in aRs
				if aResult.count >= WIN_COUNT and aResult.esc is 0
					return true
			return false

		resetMN = (t_minX, t_maxX, t_minY, t_maxY) ->
			minX = t_minX
			maxX = t_maxX
			minY = t_minY
			maxY = t_maxY
			return

		makeMove = (move, currentTurn) ->
			update move.x, move.y, CHESS_NONE
			updateScore move.x, move.y, -1
			if currentTurn is 1
				whiteMoves.push move
			else
				blackMoves.push move
			update move.x, move.y, currentTurn
			updateScore move.x, move.y, 1
			return

		unMakeMove = (move) ->
			if chessBoard[move.x][move.y] is CHESS_WHITE
				id = whiteMoves.indexOf move
				whiteMoves.splice id, 1 if id > -1
			else
				id = blackMoves.indexOf move
				blackMoves.splice id, 1 if id > -1
			chessBoard[move.x][move.y] = CHESS_NONE
			return

		updateScore = (x, y, nopSign) ->
			addedScore = getScore x, y
			score += nopSign * addedScore
			return

		getScore = (x, y) ->
			checkResults = genAnalysisResult x, y
			addedScore = 0
			for analysisResult in checkResults
				addedScore += genScore analysisResult
			return addedScore

		alphaBeta = (currentDepth, alpha, beta, currentTurn) ->
			return evaluate() if currentDepth is 0
			currentScore = 0
			candidates = getCandidates()
			if currentDepth is depth and not bestMove
				bestMove = candidates[0]
			for candidate in candidates
				if candidate.score is 0
					continue
				t_minX = minX
				t_maxX = maxX
				t_minY = minY
				t_maxY = maxY
				lastScore = score
				makeMove candidate, currentTurn
				if depth is currentDepth
					if isWin candidate
						unMakeMove candidate
						bestMove = candidate
						return - 1
					chessBoard[candidate.x][candidate.y] = 1 - currentTurn
					if isWin candidate
						chessBoard[candidate.x][candidate.y] = currentTurn
						unMakeMove candidate
						bestMove = candidate
						return - 1
					chessBoard[candidate.x][candidate.y] = currentTurn

				currentScore = - alphaBeta (currentDepth - 1), - beta, - alpha, (1 - currentTurn)

				unMakeMove candidate
				score = lastScore
				resetMN t_minX, t_maxX, t_minY, t_maxY
				if currentScore >= beta
					return beta
				if currentScore > alpha
					alpha = currentScore
					if depth is currentDepth
						bestMove = candidate
				if new Date().getTime() - startTime > timesUp
					return alpha
			return alpha

		initMoves = ->
			blackMoves = []
			whiteMoves = []
			for chessRow, i in chessBoard
				for chessCell, j in chessRow
					if chessCell is CHESS_BLACK
						blackMoves.push new Move i, j
					else if chessCell is CHESS_WHITE
						whiteMoves.push new Move i, j
			return

		getCandidates = ->
			candidates = []
			candidates.cache = {}
			for whiteMove in whiteMoves
				addCandidatesAround candidates, whiteMove
			for blackMove in blackMoves
				addCandidatesAround candidates, blackMove
			for candidate in candidates
				candidate.score = getSinglePointScore candidate.x, candidate.y
			candidates.sort (candA, candB) ->	
				return candB.score - candA.score
			return candidates

		getSinglePointScore = (x, y) ->
			checkResults = []
			# genScoreHorizontal
			analysisSinglePoint x, y, 1, 0, 1, 0, checkResults
			analysisSinglePoint x, y, 1, 0, 1, 1, checkResults
			# genScoreVetical
			analysisSinglePoint x, y, 0, 1, 0, 0, checkResults
			analysisSinglePoint x, y, 0, 1, 0, 1, checkResults
			# genScoreUpperLeft
			analysisSinglePoint x, y, 1, 1, 2, 0, checkResults
			analysisSinglePoint x, y, 1, 1, 2, 1, checkResults
			# genScoreUpperRight
			analysisSinglePoint x, y, -1, 1, 3, 0, checkResults
			analysisSinglePoint x, y, -1, 1, 3, 1, checkResults
			addedScore = 0
			for analysisResult in checkResults
				addedScore += Math.abs genScore analysisResult
			return addedScore

		analysisSinglePoint = (startX, startY, addX, addY, searchType, type, analysisResults) ->
			count = 0
			esc = 0
			nextX = startX
			nextY = startY
			leftContinueCount = 0
			chessBoard[startX][startY] = type
			while nextX < BOARD_LENGTH and nextY < BOARD_LENGTH and 
					nextX > -1 and nextY > -1
				if getChessValue(nextX, nextY, searchType) is type
					count++
				else if esc is 0 and getChessValue(nextX, nextY, searchType) is 2
					esc = 1
					leftContinueCount = count
				else
					break
				nextX += addX
				nextY += addY

			rsc = 0
			if getChessValue(nextX, nextY, searchType) is 2
				rsc++
			if getChessValue(nextX - addX, nextY - addY, searchType) is 2
				rsc++
				esc = 0
			nextX = startX - addX
			nextY = startY - addY
			while nextX < BOARD_LENGTH and nextY < BOARD_LENGTH and 
					nextX > -1 and nextY > -1
				if getChessValue(nextX, nextY, searchType) is type
					count++
				else if esc is 0 and getChessValue(nextX, nextY, searchType) is 2
					esc = 1
					leftContinueCount = count
				else
					break
				nextX -= addX
				nextY -= addY

			lsc = 0
			if getChessValue(nextX, nextY, searchType) is 2
				lsc++
			if getChessValue(nextX + addX, nextY + addY, searchType) is 2
				lsc++
				esc = 0

			needSpacesCount = WIN_COUNT + 1 - count - rsc - esc - lsc;
			lsn_x_start = startX - addX
			lsn_y_start = startY - addY
			# Ensure we know activity
			if count + rsc + esc >= WIN_COUNT + 1
				if getChessValue(startX - addX, startY - addY, searchType) is 2
					lsc++
			while needSpacesCount > 0
				if getChessValue(lsn_x_start, lsn_y_start, searchType) is 2
					lsc++
				else
					break
				lsn_x_start -= addX
				lsn_y_start -= addY
				needSpacesCount--

			if getChessValue(nextX, nextY, searchType) is 2
				rsn_x_start = nextX + addX
				rsn_y_start = nextY + addY
				while needSpacesCount > 0
					if getChessValue(rsn_x_start, rsn_y_start, searchType) is 2
						rsc++
					else
						break
					rsn_x_start += addX
					rsn_y_start += addY
					needSpacesCount--

			if count + lsc + rsc + esc >= WIN_COUNT
				analysisResults.push new AnalysisResult count, esc, 0, type, lsc, rsc, searchType, leftContinueCount

			chessBoard[startX][startY] = CHESS_NONE
			return

		addCandidatesAround = (candidates, move) ->
			x = move.x
			y = move.y
			maxXY = BOARD_LENGTH - 1
			ul_x = if x > 0 then x - 1 else 0
			ul_y = if y > 0 then y - 1 else 0
			lr_x = if x < maxXY then x + 1 else maxXY
			lr_y = if y < maxXY then y + 1 else maxXY
			for j in [ul_y..lr_y]
				for i in [ul_x..lr_x]
					if chessBoard[i][j] is CHESS_NONE
						nMove = new Move i, j
						if not candidates.cache[i + "_" + j]
							candidates.push nMove
							candidates.cache[i + "_" + j] = true
			return

		evaluate = ->
			return score if score isnt -1
			analysisResults = genAnalysisResult()
			for analysisResult in analysisResults
				score += genScore analysisResult
			return score

		genScore = (analysisResult) ->
			count = analysisResult.count
			type = analysisResult.type
			esc = analysisResult.esc
			lsc = analysisResult.lsc
			rsc = analysisResult.rsc
			leftContinueCount = analysisResult.leftContinueCount
			times = 1
			lScore = 0
			nopSign = 1
			sCount = WIN_COUNT
			if type is 1 - myTurn
				nopSign = -1
			else 
				times = 1.1
			if count is 5
				if myTurn is 1 and type is 0
					times = 2
				# AAAAA
				# +AA+AAA+
				# +A+AAAA+, +AAAA+A+ 4320 + 20
				# +A+AAAA, AAAA+A 720 + 20
				# +AA+AAA+, +AAA+AA+ 720 + 120
				# AAA+AA+, +AA+AAA 120 + 120
				if esc is 0
					lScore = 50000
				else
					rightCoutinueCount = count - leftContinueCount
					if (rightCoutinueCount is 4 and rsc is 1) or (leftContinueCount is 4 and lsc is 1)
						lScore = 4320 + 20
					else if (rightCoutinueCount is 4 and rsc is 0) or (leftContinueCount is 4 and lsc is 0)
						lScore = 720 + 20
					else if (rightCoutinueCount is 3 and rsc is 1) or (leftContinueCount is 3 and lsc is 1)
						lScore = 720 + 120
					else if (rightCoutinueCount is 3 and rsc is 0) or (leftContinueCount is 3 and lsc is 0)
						lScore = 120 + 120
					else
						lScore = 120 + 120
				return nopSign * lScore * times
			if count > 5
				# AAAAAA
				# +AAAA+AA, AAAA+AA
				# AAA+AAA
				if myTurn is 1 and type is 0
					times = 2
				if esc is 0
					lScore = 500000
				else
					rightCoutinueCount = count - leftContinueCount
					if leftContinueCount > 5 or rightCoutinueCount > 5
						lScore = 500000
					else if leftContinueCount is 5 or rightCoutinueCount is 5
						lScore = 50000
					else
						if (rightCoutinueCount is 4 and rsc is 1) or (leftContinueCount is 4 and lsc is 1)
							if rightCoutinueCount + leftContinueCount is 8
								lScore = 4320 + 4320
							else if rightCoutinueCount + leftContinueCount is 7
								lScore = 4320 + 720
							else if rightCoutinueCount + leftContinueCount is 6
								lScore = 4320 + 120
							else
								lScore = 4320 + 120
						else if (rightCoutinueCount is 4 and rsc is 0)  or (leftContinueCount is 4 and lsc is 0)
							if rightCoutinueCount + leftContinueCount is 8
								lScore = 720 + 4320
							else if rightCoutinueCount + leftContinueCount is 7
								lScore = 720 + 720
							else if rightCoutinueCount + leftContinueCount is 6
								lScore = 720 + 120
							else
								lScore = 720 + 120
						else if (rightCoutinueCount is 3 and rsc is 1) or (leftContinueCount is 3 and lsc is 1)
							lScore = 720 + 720
						else if (rightCoutinueCount is 3 and rsc is 0) or (leftContinueCount is 3 and lsc is 0)
							lScore = 120 + 120 + 120
						else
							lScore = 120 + 120 + 120
				return nopSign * lScore * times

			switch count
				when 1
					# +++A++ 20
					# A+++++, +++++A 10
					# ++A++ 5
					# A++++, ++++A 5
					if myTurn is 1 and type is 0
						times = 1.5
					sCount = WIN_COUNT - 1
					if lsc is 0 or rsc is 0
						if lsc > sCount or rsc > sCount
							lScore = 10
						else 
							lScore = 5
					else if lsc + rsc is sCount
						lScore = 5
					else if lsc + rsc > sCount
						lScore = 20
					else
						# for others havn't taken into consideration
						lScore = 5
				when 2
					if myTurn is 1 and type is 0
						times = 1.5
					sCount = WIN_COUNT - 2
					# ++AA++ 120 d
					# ++++AA | AA++++ 60 d
					# +++AA | AA+++ 20 d
					# ++AA+ 20 d
					# ++A+A+ 120 d
					# +++A+A | A+A+++ 40 d
					# ++A+A | A+A++ 20 d
					if esc is 0
						if lsc != 0 and rsc != 0 and lsc + rsc > sCount
							lScore = 120
						else if lsc is 0 or rsc is 0
							if lsc + rsc > sCount
								lScore = 60
							else
								lScore = 20
					else if esc is 1
						sCount = WIN_COUNT - 3
						if lsc != 0 and rsc != 0 and lsc + rsc > sCount
							lScore = 120
						else if lsc is 0 or rsc is 0
							if lsc + rsc > sCount
								lScore = 40
							else
								lScore = 20
					else
						# for others havn't taken into consideration
						lScore = 20
				when 3
					if myTurn is 1 and type is 0
						times = 2
					sCount = WIN_COUNT - 3
					# ++AAA+ 840 d
					# AAA+++ | +++AAA 360 d
					# +AAA+ | AAA++ | ++AAA 120 d
					# +AA+A+ 720 d
					# ++AA+A | A+AA++ 240 d
					# +AA+A | A+AA+ 120 d
					if esc is 0
						if lsc != 0 and rsc != 0 and lsc + rsc > sCount
							lScore = 840
						else if lsc is 0 or rsc is 0
							if lsc + rsc > sCount
								lScore = 360
							else
								lScore = 120
					else if esc is 1
						sCount = WIN_COUNT - 4
						if lsc != 0 and rsc != 0 and lsc + rsc > sCount
							lScore = 720
						else if lsc is 0 or rsc is 0
							if lsc + rsc > sCount
								lScore = 240
							else 
								lScore = 120
					else 
						# for others havn't taken into consideration
						lScore = 120
				when 4
					if myTurn is 1 and type is 0
						times = 2
					sCount = WIN_COUNT - 4
					# +AAAA+ 5000 d
					# ++AAAA | AAAA++ 720 d
					# +AAAA | AAAA+ 720 d
					# +AA+AA+ 4320 d
					# AA+AA+ | +AA+AA 1440 d
					# AA+AA 720 d
					if esc is 0
						if lsc != 0 and rsc != 0 and lsc + rsc > sCount
							lScore = 5000
						else if lsc is 0 or rsc is 0
							if lsc + rsc > sCount
								lScore = 720
							else
								lScore = 720
					else if esc is 1
						if lsc != 0 and rsc != 0 and lsc + rsc > sCount
							lScore = 4320
						else if lsc is 0 or rsc is 0
							if lsc + rsc > 0
								lScore = 1440
							else
							lScore = 720
					else
						# for others havn't taken into consideration
						lScore = 720

			return nopSign * lScore * times

		genAnalysisResult = ->
			checkResults = []
			# genScoreHorizontal
			for i in [minY...maxY + 1]
				analysis minX, i, 1, 0, 1, checkResults

			# genScoreVerticle
			for i in [minX...maxX + 1]
				analysis i, minY, 0, 1, 0, checkResults

			for i in [minX...maxX + 1]
				# genScoreUpperLeft
				analysis i, minY, 1, 1, 2, checkResults
				# genScoreUpperRight
				analysis i, minY, -1, 1, 3, checkResults

			for i in [minY + 1...maxY + 1]
				# genScoreUpperLeft
				analysis minX, i, 1, 1, 2, checkResults
				# genScoreUpperRight
				analysis maxX, i, -1, 1, 3, checkResults
			return checkResults

		analysis = (x, y, addX, addY, searchType, analysisResults) ->
			if not (x < maxX + 1 and y < maxY + 1 and x > minX - 1 and y > minY - 1)
				return
			startXY = skipSpaces x, y, addX, addY, searchType
			if startXY[0] == -1 and startXY[1] == -1
				return

			type = getChessValue startXY[0], startXY[1], searchType
			count = 0
			esc = 0
			nextX = startXY[0]
			nextY = startXY[1]
			leftContinueCount = 0
			while nextX < maxX + 1 and nextY < maxY + 1 and nextX > minX - 1 and nextY > minY - 1
				if getChessValue(nextX, nextY, searchType) is type
					count++
				else if esc is 0 and getChessValue(nextX, nextY, searchType) is 2
					esc = 1
					leftContinueCount = count
				else
					break
				nextX += addX
				nextY += addY

			rsc = 0
			if getChessValue(nextX, nextY, searchType) is 2
				rsc++
			if getChessValue(nextX - addX, nextY - addY, searchType) is 2
				rsc++
				esc = 0
			if leftContinueCount is 0 and esc is 0
				leftContinueCount = count
			needSpacesCount = WIN_COUNT + 1 - count - rsc - esc;
			lsc = 0
			lsn_x_start = startXY[0] - addX
			lsn_y_start = startXY[1] - addY
			# Ensure we know activity
			if count + rsc + esc >= WIN_COUNT + 1
				if getChessValue(startXY[0] - addX, startXY[1] - addY, searchType) is 2
					lsc++
			while needSpacesCount > 0
				if getChessValue(lsn_x_start, lsn_y_start, searchType) is 2
					lsc++
				else
					break
				lsn_x_start -= addX
				lsn_y_start -= addY
				needSpacesCount--

			if getChessValue(nextX, nextY, searchType) is 2
				rsn_x_start = nextX + addX
				rsn_y_start = nextY + addY
				while needSpacesCount > 0
					if getChessValue(rsn_x_start, rsn_y_start, searchType) is 2
						rsc++
					else
						break
					rsn_x_start += addX
					rsn_y_start += addY
					needSpacesCount--

			if count + lsc + rsc + esc >= WIN_COUNT
				analysisResults.push new AnalysisResult count, esc, 0, type, lsc, rsc, searchType, leftContinueCount

			analysis nextX, nextY, addX, addY, searchType, analysisResults
			return

		getChessValue = (x, y, searchType) ->
			if not(x < BOARD_LENGTH and y < BOARD_LENGTH and x > -1 and y > -1)
				return -1
			return chessBoard[x][y]

		skipSpaces = (x, y, addX, addY, searchType) ->
			nextX = x
			nextY = y
			while getChessValue(nextX, nextY, searchType) is 2
				nextX += addX
				nextY += addY
				if not(nextX < maxX + 1 and nextY < maxY + 1 and nextX > minX - 1 and nextY > minY - 1)
					return [-1, -1]
			return [nextX, nextY]

		class AnalysisResult
			#count: count of black/white
			#esc: count of empty chess spaces
			#isContinueE: is two empty chess together
			#type: 0: black, 1: white
			#lsc: count of left space
			#rsc: count of right space
			constructor: (@count = 0, @esc = 0, @isContinueE = 0, @type = 0, @lsc = 0, @rsc = 0, @searchType, @leftContinueCount = 0) ->
			toString: ->
				return "Type is: #{if type is 0 then Black else White};
				SearchType is: #{searchType};
				count is: #{count};
				esc is : #{esc};
				isContinueE: #{isContinueE};
				lsc is: #{lsc};
				rsc is: #{rsc}
				"


	window.Player = Player
	window.AIPlayer= AIPlayer

	class StartUpMove
		root = {}
		class MoveLink
			constructor: (@currentMove, @nextMoves = []) ->
		constructor: () ->
			@init()
		init: ->
			centerXY = Math.floor BOARD_LENGTH/2
			root = new MoveLink (new Move centerXY, centerXY)
			root_move = root.currentMove
			x = root_move.x
			y = root_move.y

			child11 = new MoveLink()
			child11.currentMove = new Move(x - 1, y + 1)
			child12 = new MoveLink()
			child12.currentMove = new Move(x + 1, y - 1)
			child21 = new MoveLink()
			child21.currentMove = new Move(x, y + 1)
			child22 = new MoveLink()
			child22.currentMove = new Move(x, y - 1)
			root.nextMoves.push child11
			root.nextMoves.push child12
			root.nextMoves.push child21
			root.nextMoves.push child22

			child11_nextMoves = child11.nextMoves
			child11_1 = new MoveLink()
			child11_1.currentMove = new Move(x - 1, y - 1)
			child11_2 = new MoveLink()
			child11_2.currentMove = new Move(x - 2, y)
			child11_3 = new MoveLink()
			child11_3.currentMove = new Move(x - 1, y)
			child11_4 = new MoveLink()
			child11_4.currentMove = new Move(x - 2, y - 1)
			child11_5 = new MoveLink()
			child11_5.currentMove = new Move(x - 2, y + 1)
			child11_6 = new MoveLink()
			child11_6.currentMove = new Move(x + 1, y - 1)
			child11_7 = new MoveLink()
			child11_7.currentMove = new Move(x - 2, y + 2)
			child11_8 = new MoveLink()
			child11_8.currentMove = new Move(x + 2, y)
			child11_9 = new MoveLink()
			child11_9.currentMove = new Move(x - 2, y - 2)
			child11_10 = new MoveLink()
			child11_10.currentMove = new Move(x - 1, y - 2)
			child11_11 = new MoveLink()
			child11_11.currentMove = new Move(x + 1, y)
			child11_12 = new MoveLink()
			child11_12.currentMove = new Move(x + 1, y - 2)
			child11_13 = new MoveLink()
			child11_13.currentMove = new Move(x + 2, y - 2)
			child11_14 = new MoveLink()
			child11_14.currentMove = new Move(x - 2, y + 1)
			child11_nextMoves.push child11_1
			child11_nextMoves.push child11_2
			child11_nextMoves.push child11_3
			child11_nextMoves.push child11_4
			child11_nextMoves.push child11_5
			child11_nextMoves.push child11_6
			child11_nextMoves.push child11_7
			child11_nextMoves.push child11_8
			child11_nextMoves.push child11_9
			child11_nextMoves.push child11_10
			child11_nextMoves.push child11_11
			child11_nextMoves.push child11_12
			child11_nextMoves.push child11_13
			child11_nextMoves.push child11_14

			child12_nextMoves = child12.nextMoves
			child12_1 = new MoveLink()
			child12_1.currentMove = new Move(x + 2, y - 2)
			child12_2 = new MoveLink()
			child12_2.currentMove = new Move(x + 2, y - 1)
			child12_3 = new MoveLink()
			child12_3.currentMove = new Move(x + 2, y)
			child12_4 = new MoveLink()
			child12_4.currentMove = new Move(x + 2, y + 1)
			child12_5 = new MoveLink()
			child12_5.currentMove = new Move(x + 2, y + 2)
			child12_6 = new MoveLink()
			child12_6.currentMove = new Move(x + 1, y)
			child12_7 = new MoveLink()
			child12_7.currentMove = new Move(x + 1, y + 1)
			child12_8 = new MoveLink()
			child12_8.currentMove = new Move(x + 1, y + 2)
			child12_9 = new MoveLink()
			child12_9.currentMove = new Move(x, y + 1)
			child12_10 = new MoveLink()
			child12_10.currentMove = new Move(x, y + 2)
			child12_11 = new MoveLink()
			child12_11.currentMove = new Move(x - 1, y + 1)
			child12_12 = new MoveLink()
			child12_12.currentMove = new Move(x - 1, y + 2)
			child12_13 = new MoveLink()
			child12_13.currentMove = new Move(x - 2, y - 2)
			child12_nextMoves.push child12_1
			child12_nextMoves.push child12_2
			child12_nextMoves.push child12_3
			child12_nextMoves.push child12_4
			child12_nextMoves.push child12_5
			child12_nextMoves.push child12_6
			child12_nextMoves.push child12_7
			child12_nextMoves.push child12_8
			child12_nextMoves.push child12_9
			child12_nextMoves.push child12_10
			child12_nextMoves.push child12_11
			child12_nextMoves.push child12_12
			child12_nextMoves.push child12_13

			child21_nextMoves = child21.nextMoves
			child21_1 = new MoveLink()
			child21_1.currentMove = new Move(x + 1, y + 1)
			child21_2 = new MoveLink()
			child21_2.currentMove = new Move(x, y + 2)
			child21_3 = new MoveLink()
			child21_3.currentMove = new Move(x + 1, y)
			child21_4 = new MoveLink()
			child21_4.currentMove = new Move(x + 2, y)
			child21_5 = new MoveLink()
			child21_5.currentMove = new Move(x + 2, y + 1)
			child21_6 = new MoveLink()
			child21_6.currentMove = new Move(x + 2, y - 1)
			child21_7 = new MoveLink()
			child21_7.currentMove = new Move(x + 1, y - 2)
			child21_8 = new MoveLink()
			child21_8.currentMove = new Move(x + 1, y - 1)
			child21_9 = new MoveLink()
			child21_9.currentMove = new Move(x, y - 1)
			child21_10 = new MoveLink()
			child21_10.currentMove = new Move(x, y - 2)
			child21_11 = new MoveLink()
			child21_11.currentMove = new Move(x + 2, y + 2)
			child21_12 = new MoveLink()
			child21_12.currentMove = new Move(x - 2, y - 2)
			child21_nextMoves.push child21_1
			child21_nextMoves.push child21_2
			child21_nextMoves.push child21_3
			child21_nextMoves.push child21_4
			child21_nextMoves.push child21_5
			child21_nextMoves.push child21_6
			child21_nextMoves.push child21_7
			child21_nextMoves.push child21_8
			child21_nextMoves.push child21_9
			child21_nextMoves.push child21_10
			child21_nextMoves.push child21_11
			child21_nextMoves.push child21_12

			child22_nextMoves = child22.nextMoves
			child22_1 = new MoveLink()
			child22_1.currentMove = new Move(x, y - 2)
			child22_2 = new MoveLink()
			child22_2.currentMove = new Move(x + 1, y - 2)
			child22_3 = new MoveLink()
			child22_3.currentMove = new Move(x + 2, y - 2)
			child22_4 = new MoveLink()
			child22_4.currentMove = new Move(x + 1, y - 1)
			child22_5 = new MoveLink()
			child22_5.currentMove = new Move(x + 2, y - 1)
			child22_6 = new MoveLink()
			child22_6.currentMove = new Move(x + 1, y)
			child22_7 = new MoveLink()
			child22_7.currentMove = new Move(x + 2, y)
			child22_8 = new MoveLink()
			child22_8.currentMove = new Move(x, y + 1)
			child22_9 = new MoveLink()
			child22_9.currentMove = new Move(x + 1, y + 1)
			child22_10 = new MoveLink()
			child22_10.currentMove = new Move(x + 2, y + 1)
			child22_11 = new MoveLink()
			child22_11.currentMove = new Move(x, y + 2)
			child22_12 = new MoveLink()
			child22_12.currentMove = new Move(x + 1, y + 2)
			child22_13 = new MoveLink()
			child22_13.currentMove = new Move(x + 2, y + 2)
			child22_nextMoves.push child22_1
			child22_nextMoves.push child22_2
			child22_nextMoves.push child22_3
			child22_nextMoves.push child22_4
			child22_nextMoves.push child22_5
			child22_nextMoves.push child22_6
			child22_nextMoves.push child22_7
			child22_nextMoves.push child22_8
			child22_nextMoves.push child22_9
			child22_nextMoves.push child22_10
			child22_nextMoves.push child22_11
			child22_nextMoves.push child22_12
			child22_nextMoves.push child22_13
			return
		getNextMove: (currentTurn, chessNum, lastMove) ->
			if currentTurn is 0 and chessNum is 0
				return root.currentMove
			if currentTurn is 0 and chessNum is 2
				moveLinks = root.nextMoves
				lastX = lastMove[0]
				lastY = lastMove[1]
				whiteMove = new Move lastX, lastY
				for moveLink in moveLinks
					if moveLink.currentMove.x is whiteMove.x and moveLink.currentMove.y is whiteMove.y
						lastMoveLink = moveLink
						break
				if lastMoveLink
					nmSize = lastMoveLink.nextMoves.length
					nextId = Math.floor Math.random()*nmSize
					nextMoveLink = lastMoveLink.nextMoves[nextId]
					return nextMoveLink.currentMove
			return