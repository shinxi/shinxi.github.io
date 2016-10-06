$ ->
	GAME_CONFIG = 
		CHESS_NONE: 2
		CHESS_BLACK: 0
		CHESS_WHITE: 1
		BOARD_LENGTH: 19
		WIN_COUNT: 5
	window.GAME_CONFIG = GAME_CONFIG
	S_xAdd = 22
	S_yAdd = 22
	chessSize = 36
	chessBoard = []
	S_chessBoardLength = GAME_CONFIG.BOARD_LENGTH
	CHESS_NONE = GAME_CONFIG.CHESS_NONE
	CHESS_BLACK = GAME_CONFIG.CHESS_BLACK
	CHESS_WHITE = GAME_CONFIG.CHESS_WHITE
	currentTurn = 0
	isFirstPlayer = false
	isDev = true

	class GameEngine
		constructor: (@board) ->
			if isFirstPlayer
				@player1 = new HumanPlayer @, currentTurn
				# @player1 = new window.AIPlayer2 currentTurn
				@player1.setName "Player1"
				@player2 = new window.AIPlayer 1 - currentTurn
				@player2.setName "Player2"
			else
				@player1 = new window.AIPlayer currentTurn
				@player1.setName "Player1"
				@player2 = new HumanPlayer @, 1 - currentTurn
				# @player2 = new window.AIPlayer2 1 - currentTurn
				@player2.setName "Player2"
			@currentPlayer = @player1
			@currentMove = []
		showSuccess: ->
			$("#winDialog").dialog
				resizable: false,
				height: 300,
				modal: false,
				buttons:
					OK: ->
						$(@).dialog "close"
						$("#playerOrder input:checked").trigger 'click'
						$("#btnStart").trigger 'click'
						return
					Cancel: ->
						$(@).dialog "close"
						return
			return
		showFailure: ->
			$("#loseDialog").dialog
				resizable: false,
				height: 300,
				modal: false,
				buttons:
					OK: ->
						$(@).dialog "close"
						$("#playerOrder input:checked").trigger 'click'
						$("#btnStart").trigger 'click'
						return
					Cancel: ->
						$(@).dialog "close"
						return
			return
		play: ->
			if result = @isWin()
				console.log result
				if (result[1] is 0 and isFirstPlayer) or (result[1] is 1 and not isFirstPlayer)
					@showSuccess()
				else if (result[1] is 0 and not isFirstPlayer) or (result[1] is 1 and isFirstPlayer)
					@showFailure()
				return
			currentPlayer = @currentPlayer
			if (currentPlayer instanceof HumanPlayer)
				return
			st = new Date().getTime()
			nextMove = currentPlayer.getMove @currentMove
			console.log currentPlayer.toString(), 'spent', new Date().getTime() - st
			@update nextMove
			return
		update: (move) ->
			console.log @currentPlayer.toString(), "is making the move"
			@currentMove = move
			@board.update move
			if @currentPlayer is @player1
				@currentPlayer = @player2
			else 
				@currentPlayer = @player1
			play = _.bind @play, @
			setTimeout play, 200
			return
		isWin: ->
			isChessAtRange = (x, y) ->
				return x > -1 and x < S_chessBoardLength and y > -1 and y < S_chessBoardLength
			checkFive = (x, y, addX, addY) ->
				while chessBoard[x][y] is CHESS_NONE
					x += addX
					y += addY
					return if not isChessAtRange(x, y)
				type = chessBoard[x][y]
				count = 0
				while chessBoard[x][y] is type
					count++
					x += addX
					y += addY
					return [1, type] if count is GAME_CONFIG.WIN_COUNT
					return if not isChessAtRange(x, y)
				return checkFive x, y, addX, addY
			for i in [0...S_chessBoardLength]
				result = checkFive i, 0, 0, 1
				return result if result
			for i in [0...S_chessBoardLength]
				result = checkFive 0, i, 1, 0
				return result if result
			for i in [4...S_chessBoardLength]
				result = checkFive i, 0, -1, 1
				return result if result
			for i in [4...S_chessBoardLength]
				result = checkFive i, 0, -1, 1
				return result if result
				result = checkFive S_chessBoardLength - 1 - i, 0, 1, 1
				return result if result
			for i in [1...S_chessBoardLength - 4]
				result = checkFive S_chessBoardLength - 1, i, -1, 1
				return result if result
				result = checkFive 0, i, 1, 1
				return result if result
			return

	class HumanPlayer extends window.Player
		constructor: (gameEngine, myTurn) ->
			@view = new HumanPlayerView gameEngine, myTurn

	paintChess = (ctx, x, y) ->
		radius = chessSize/2 - 3
		circleCenterX = S_xAdd + chessSize * x
		circleCenterY = S_yAdd + chessSize * y

		ctx.beginPath()
		grd = ctx.createRadialGradient circleCenterX, circleCenterY, radius/10, circleCenterX, circleCenterY, radius
		grd.addColorStop 0, if currentTurn is 0 then "#777" else "#fff"
		grd.addColorStop 1, if currentTurn is 0 then "#222" else "#d3d3d3"
		ctx.fillStyle = grd
		ctx.arc circleCenterX, circleCenterY, radius, 0, 2 * Math.PI
		ctx.fill()
		return

	HumanPlayerView = Backbone.View.extend
		el: $("#main > #chess")
		mouseMoveAt: []
		events: 
			"mousemove": "onMouseMove"
			"click": "onClick"
		initialize: (gameEngine, @myTurn)->
			board =  gameEngine.board
			ctx = @el.getContext "2d"
			@ctx = ctx
			@el.width = board.el.width
			@el.height = board.el.height
			@gameEngine = gameEngine
			return
		onClick: (event) ->
			if @myTurn isnt currentTurn or @mouseMoveAt.length isnt 2
				return
			mouseMoveAt = @mouseMoveAt
			@playChessSound()
			@gameEngine.update mouseMoveAt
			@mouseMoveAt = []
			return
		onMouseMove: (event) ->
			if @myTurn isnt currentTurn
				return
			$el = @$el
			paddingLeft = parseInt $el.css "padding-left"
			paddingRight = parseInt $el.css "padding-right"
			offsetX = event.offsetX - S_xAdd - paddingLeft
			offsetY = event.offsetY - S_yAdd - paddingRight
			x = Math.round offsetX/chessSize
			y = Math.round offsetY/chessSize
			x = 0 if x < 0
			x = S_chessBoardLength - 1 if x >= S_chessBoardLength
			y = 0 if y < 0
			y = S_chessBoardLength - 1 if y >= S_chessBoardLength
			if (@mouseMoveAt[0] isnt x or @mouseMoveAt[1] isnt y) and chessBoard[x][y] is 2
				@mouseMoveAt = [x, y]
				@clearCanvas @ctx
				paintChess @ctx, x, y
			return
		playChessSound: ->
			$("#chessPutSound")[0].play()
			return
		clearCanvas: (ctx)->
			ctx.clearRect 0, 0, @el.width, @el.height
			return
		render: ->
			return


	Board = Backbone.View.extend
		el: $("#main > #board")
		
		initialize: ->
			ctx = @el.getContext "2d"
			@ctx = ctx
			@render()
			return
		render: ->
			ctx = @ctx
			@chessNum = 0
			ctx.clearRect 0, 0, @el.width, @el.height
			S_chessBoardLength = GAME_CONFIG.BOARD_LENGTH
			chessBoardLength = S_chessBoardLength
			xAdd = S_xAdd
			yAdd = S_yAdd
			chessBoardWidth = chessSize * (chessBoardLength - 1) + xAdd * 2
			chessBoardHeight = chessSize * (chessBoardLength - 1) + yAdd * 2
			@el.width = chessBoardWidth
			@el.height = chessBoardHeight
			chessBoardWidthUnit = (chessBoardWidth - xAdd * 2) / (chessBoardLength - 1)
			chessBoardHeightUnit = (chessBoardHeight - yAdd * 2) / (chessBoardLength - 1)
			ctx.lineWidth = 1
			while chessBoardLength-- > 0
				x = chessBoardWidthUnit * chessBoardLength + xAdd
				ctx.moveTo x, yAdd
				ctx.lineTo x, chessBoardHeight - yAdd
				ctx.stroke()

			chessBoardLength = S_chessBoardLength
			while chessBoardLength-- > 0
				y = chessBoardHeightUnit * (chessBoardLength) + yAdd
				ctx.moveTo xAdd, y
				ctx.lineTo chessBoardWidth - xAdd , y
				ctx.stroke()

			for i in [0...S_chessBoardLength]
				chessBoard[i] = []
				for j in [0...S_chessBoardLength]
					chessBoard[i][j] = CHESS_NONE

			return
		update: (move) ->
			x = move[0]
			y = move[1]
			chessBoard[x][y] = currentTurn
			@chessNum++
			paintChess @ctx, x, y
			if isDev
				circleCenterX = S_xAdd + chessSize * x
				circleCenterY = S_yAdd + chessSize * y
				@ctx.fillStyle = 'white'
				if currentTurn is 1
					@ctx.fillStyle = 'black'

				@ctx.fillText @chessNum, circleCenterX - 3, circleCenterY + 3
			# a hack here to refresh the canvas to avoid half painting
			chessContext = $("#main > #chess")[0].getContext "2d"
			chessContext.clearRect 0, 0, @el.width, @el.height
			currentTurn = 1- currentTurn
			return
	AppView = Backbone.View.extend
		el: $("#main")
		initialize: ->
			@render()
			return
		render: ->
			gameEngine = ''
			$("#boardSetting, #playerOrder").buttonset()
			$("#board_15_15").click ->
				GAME_CONFIG.BOARD_LENGTH = 15
				gameEngine = new GameEngine(new Board())
				console.log "board_15-15 clicked"
				return
			$("#board_19_19").click ->
				GAME_CONFIG.BOARD_LENGTH = 19
				gameEngine = new GameEngine(new Board())
				console.log "board_19_19 clicked"
				return
			$("#firstPlayer").click ->
				isFirstPlayer = true
				return
			$("#secondPlayer").click ->
				isFirstPlayer = false
				return
			$("#chessSetting #buttons button").button()
			$("#btnStart").click ->
				currentTurn = 0
				gameEngine = new GameEngine(new Board())
				gameEngine.play()
				console.log 'btnStart'
				return
			$("#btnRestart").click ->
				$("#btnStart").trigger 'click'
				console.log 'btnRestart'
				return
			$("#btnQuit").click ->
				console.log 'btnQuit'
				return
			new Board()
			# gameEngine = new GameEngine(new Board())
			return
	App = new AppView
