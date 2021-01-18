package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class PlayState extends FlxState
{
	private var TS:Int = 37; // the size of the tiles of the game field
	private var fieldArray:Array<Array<Int>>; // the array that will numerically represent the game field
	private var fieldSprite:FlxGroup; // the DisplayObject that will graphically render the game field
	private var tetrominoes:Array<Array<Array<Array<Int>>>>; // 4-dimensional array for all tetrominoes data
	private var colors:Array<FlxColor>; // colors of tetromimoes
	private var landed:Array<Array<FlxSprite>>;
	private var tetromino:FlxTypedSpriteGroup<FlxSprite>; // DisplayObject representing the tetromino itself
	private var currentTetromino:Int; // the number of the tetromino currently in game, and will range from 0 to 6
	private var nextTetromino:Int;
	private var currentRotation:Int;
	private var currentDirection:String;

	/**the rotation of the tetromino and will range:
		•	T,L,J - from 0 to 3
		•	I,Z,S - from 0 to 1
		•	O - only 0 (without rotation)**/
	private var tRow:Int; // the current vertical...

	private var tCol:Int; // ...and horizontal position of the tetromino in the game field
	private var tRowOffset:Int = 30;
	private var tColOffset:Int = 20;
	private var timeCount:FlxTimer = new FlxTimer();
	private var nextTetrominoShape:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup();
	private var timePassed:Float = 0;

	private var isGameOver:Bool = false;
	private var isPaused:Bool;
	private var pauseScreen:FlxSprite;

	override public function create()
	{
		super.create();
		landed = new Array<Array<FlxSprite>>();
		nextTetromino = Math.floor(Math.random() * 7);

		generateField();
		initTetrominoes();
		generateTetromino();
		pauseScreen = new FlxSprite(0, 0, "assets/images/pause.png");
		add(pauseScreen);
		isPaused = true;
	}

	override public function update(elapsed:Float)
	{
		var t = 4;

		if (FlxG.keys.justPressed.ESCAPE)
		{
			if (!isPaused)
			{
				isPaused = true;
				add(pauseScreen);
			}
			else
			{
				isPaused = false;
				remove(pauseScreen);
			}
		}
		else if (FlxG.keys.justPressed.R)
		{
			FlxG.resetGame();
		}
		else if (FlxG.keys.justPressed.ANY)
		{
			if (isGameOver)
				FlxG.resetGame();
			else
			{
				isPaused = false;
				remove(pauseScreen);
			}
		}

		timeCount.active = !isPaused;

		if (!isPaused)
		{
			if (FlxG.keys.pressed.LEFT)
			{
				timePassed++;
				if (timePassed >= t)
				{
					if (canFit(tRow, tCol - 1, currentRotation))
					{
						tCol--;
						placeTetromino();
					}
					timePassed = 0;
				}
			}

			if (FlxG.keys.pressed.RIGHT)
			{
				timePassed++;
				if (timePassed > t)
				{
					if (canFit(tRow, tCol + 1, currentRotation))
					{
						tCol++;
						placeTetromino();
					}
					timePassed = 0;
				}
			}

			if (FlxG.keys.justPressed.UP)
			{
				var ct:Int = currentRotation;
				var rot:Int = (ct + 1) % tetrominoes[currentTetromino].length;
				if (canFit(tRow, tCol, rot))
				{
					currentRotation = rot;
					remove(tetromino);
					drawTetromino();
					placeTetromino();
				}
			}

			if (FlxG.keys.pressed.DOWN)
			{
				timePassed += 2;
				if (timePassed > t)
				{
					if (canFit(tRow + 1, tCol, currentRotation))
					{
						tRow++;
						placeTetromino();
					}
					else
					{
						landTetromino();
						generateTetromino();
					}
					timePassed = 0;
				}
			}
		}

		super.update(elapsed);
	}

	private function generateField():Void
	{
		var bg:FlxSprite = new FlxSprite(0, 0, "assets/images/background.png");
		add(bg);
		var color:Array<FlxColor> = [FlxColor.fromString("0x111111"), FlxColor.fromString("0x111120")];

		fieldSprite = new FlxGroup();
		fieldArray = new Array();
		add(fieldSprite);
		for (i in 0...20)
		{
			landed[i] = new Array();

			fieldArray[i] = new Array();
			for (j in 0...10)
			{
				var tile:FlxSprite = new FlxSprite((TS * j) + tColOffset, (TS * i) + tRowOffset);
				fieldArray[i][j] = 0;
				landed[i][j] = null;
				tile.makeGraphic(TS, TS, color[(j % 2 + i % 2) % 2]);

				fieldSprite.add(tile);
			}
		}
	}

	private function initTetrominoes():Void // tetrominoes-related arrays initialization
	{
		tetrominoes = new Array<Array<Array<Array<Int>>>>();
		colors = new Array<FlxColor>();

		/** 0 -> I - Cian - 0x009FDA
			0, 0, 0, 0		0, 1, 0, 0
			1, 1, 1, 1		0, 1, 0, 0
			0, 0, 0, 0		0, 1, 0, 0
			0, 0, 0, 0		0, 1, 0, 0
		**/
		tetrominoes[0] = [
			[[0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 0, 0], [0, 0, 0, 0]],
			[[0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 0, 0]]
		];

		colors[0] = FlxColor.fromString("0x009FDA");

		/** 1 -> T - Purple - 0x952D98
			0, 0, 0, 0		0, 1, 0, 0		0, 1, 0, 0		0, 1, 0, 0
			1, 1, 1, 0		1, 1, 0, 0		1, 1, 1, 0		0, 1, 1, 0
			0, 1, 0, 0		0, 1, 0, 0		0, 0, 0, 0		0, 1, 0, 0
			0, 0, 0, 0		0, 0, 0, 0		0, 0, 0, 0		0, 0, 0, 0
		**/
		tetrominoes[1] = [
			[[0, 0, 0, 0], [1, 1, 1, 0], [0, 1, 0, 0], [0, 0, 0, 0]],
			[[0, 1, 0, 0], [1, 1, 0, 0], [0, 1, 0, 0], [0, 0, 0, 0]],
			[[0, 1, 0, 0], [1, 1, 1, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
			[[0, 1, 0, 0], [0, 1, 1, 0], [0, 1, 0, 0], [0, 0, 0, 0]]
		];

		colors[1] = FlxColor.fromString("0x952D98");

		/** 2 -> L - Orange - 0xFF7900
			0, 0, 0, 0		1, 1, 0, 0		0, 0, 1, 0		0, 1, 0, 0
			1, 1, 1, 0		0, 1, 0, 0		1, 1, 1, 0		0, 1, 0, 0
			1, 0, 0, 0		0, 1, 0, 0		0, 0, 0, 0		0, 1, 1, 0
			0, 0, 0, 0		0, 0, 0, 0		0, 0, 0, 0		0, 0, 0, 0
		**/
		tetrominoes[2] = [
			[[0, 0, 0, 0], [1, 1, 1, 0], [1, 0, 0, 0], [0, 0, 0, 0]],
			[[1, 1, 0, 0], [0, 1, 0, 0], [0, 1, 0, 0], [0, 0, 0, 0]],
			[[0, 0, 1, 0], [1, 1, 1, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
			[[0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 1, 0], [0, 0, 0, 0]]
		];

		colors[2] = FlxColor.fromString("0xFF7900");

		/** 3 -> J - Blue - 0x0065BD
			1, 0, 0, 0		0, 1, 1, 0		0, 0, 0, 0		0, 1, 0, 0
			1, 1, 1, 0		0, 1, 0, 0		1, 1, 1, 0		0, 1, 0, 0
			0, 0, 0, 0		0, 1, 0, 0		0, 0, 1, 0		1, 1, 0, 0
			0, 0, 0, 0		0, 0, 0, 0		0, 0, 0, 0		0, 0, 0, 0
		**/
		tetrominoes[3] = [
			[[1, 0, 0, 0], [1, 1, 1, 0], [0, 0, 0, 0], [0, 0, 0, 0]],
			[[0, 1, 1, 0], [0, 1, 0, 0], [0, 1, 0, 0], [0, 0, 0, 0]],
			[[0, 0, 0, 0], [1, 1, 1, 0], [0, 0, 1, 0], [0, 0, 0, 0]],
			[[0, 1, 0, 0], [0, 1, 0, 0], [1, 1, 0, 0], [0, 0, 0, 0]]
		];

		colors[3] = FlxColor.fromString("0x0065BD");

		/** 4 -> Z - Red - 0xED2939
			0, 0, 0, 0		0, 0, 1, 0
			1, 1, 0, 0		0, 1, 1, 0
			0, 1, 1, 0		0, 1, 0, 0
			0, 0, 0, 0		0, 0, 0, 0
		**/
		tetrominoes[4] = [
			[[0, 0, 0, 0], [1, 1, 0, 0], [0, 1, 1, 0], [0, 0, 0, 0]],
			[[0, 0, 1, 0], [0, 1, 1, 0], [0, 1, 0, 0], [0, 0, 0, 0]]
		];

		colors[4] = FlxColor.fromString("0xED2939");

		/** 5 -> S - Green - 0x69BE28
			0, 0, 0, 0		0, 1, 0, 0
			0, 1, 1, 0		0, 1, 1, 0
			1, 1, 0, 0		0, 0, 1, 0
			0, 0, 0, 0		0, 0, 0, 0
		**/
		tetrominoes[5] = [
			[[0, 0, 0, 0], [0, 1, 1, 0], [1, 1, 0, 0], [0, 0, 0, 0]],
			[[0, 1, 0, 0], [0, 1, 1, 0], [0, 0, 1, 0], [0, 0, 0, 0]]
		];

		colors[5] = FlxColor.fromString("0x69BE28");

		/** 6 -> O - Yellow - 0xFECB00
			0, 1, 1, 0
			0, 1, 1, 0
			0, 0, 0, 0
			0, 0, 0, 0
		**/
		tetrominoes[6] = [[[0, 1, 1, 0], [0, 1, 1, 0], [0, 0, 0, 0], [0, 0, 0, 0]]];

		colors[6] = FlxColor.fromString("0xFECB00");
	}

	private function generateTetromino():Void
	{
		if (!isGameOver)
		{
			currentTetromino = nextTetromino;
			nextTetromino = Math.floor(Math.random() * 7);
			drawNext();
			currentRotation = 0;
			tRow = 0;
			if (tetrominoes[currentTetromino][0][0].indexOf(1) == -1)
			{ // Αν το array του τετρόμινο εχει την πρώτη γραμμή άδεια,
				// πρέπει να τοποθετηθεί μια γραμμή πιο πάνω (άρα -1)
				tRow = -1;
			}
			tCol = 3;
			drawTetromino();
			if (canFit(tRow, tCol, currentRotation))
			{
				timeCount.start(0.5, onTimer, 1);

				timeCount.onComplete(timeCount);
			}
			else
			{
				isGameOver = true;
				isPaused = true;
				add(pauseScreen);
			}
		}
	}

	private function onTimer(Timer:FlxTimer):Void
	{
		if (canFit(tRow + 1, tCol, currentRotation))
		{
			tRow++;
			placeTetromino();
			timeCount.reset();
		}
		else
		{
			timeCount.cancel();
			landTetromino();
			generateTetromino();
		}
	}

	private function drawTetromino():Void
	{
		tetromino = new FlxTypedSpriteGroup();
		add(tetromino);
		// tetromino.graphics.lineStyle(0, 0x000000);
		for (i in 0...tetrominoes[currentTetromino][currentRotation].length)
		{
			for (j in 0...tetrominoes[currentTetromino][currentRotation][i].length)
			{
				if (tetrominoes[currentTetromino][currentRotation][i][j] == 1)
				{ // Για κάθε "1" που υπάρχει στο array του τετρόνιμου, ζωγράφισε ένα τετράγωνο με το ανάλογο χρώμα
					// tetromino.graphics.beginFill(colors[currentTetromino]);
					// tetromino.graphics.drawRect(TS * j, TS * i, TS, TS);
					// tetromino.graphics.endFill();

					var tile:FlxSprite = new FlxSprite(TS * j + 1, TS * i + 1);
					tile.makeGraphic(TS - 1, TS - 1, colors[currentTetromino]);
					tetromino.add(tile);
				}
			}
		}
		placeTetromino();
	}

	private function drawNext():Void
	{
		if (nextTetrominoShape.length > 0)
		{
			nextTetrominoShape.destroy();
			// while (nextTetrominoShape.length > 0)
			// {
			// 	nextTetrominoShape.
			// }
			nextTetrominoShape = new FlxTypedSpriteGroup();
		}

		switch (nextTetromino)
		{
			case 0:
				nextTetrominoShape.x = 409;
				nextTetrominoShape.y = 50;

			case 1:
				nextTetrominoShape.x = 417;
				nextTetrominoShape.y = 45;
			case 2:
				nextTetrominoShape.x = 417;
				nextTetrominoShape.y = 45;
			case 4:
				nextTetrominoShape.x = 417;
				nextTetrominoShape.y = 45;
			case 5:
				nextTetrominoShape.x = 417;
				nextTetrominoShape.y = 45;

			case 3:
				nextTetrominoShape.x = 417;
				nextTetrominoShape.y = 57;

			case 6:
				nextTetrominoShape.x = 409;
				nextTetrominoShape.y = 60;
		}

		add(nextTetrominoShape);

		for (i in 0...tetrominoes[nextTetromino][0].length)
		{
			for (j in 0...tetrominoes[nextTetromino][0][i].length)
			{
				if (tetrominoes[nextTetromino][0][i][j] == 1)
				{
					var tile:FlxSprite = new FlxSprite(TS * j * .4 + 1, TS * i * .4 + 1);

					tile.makeGraphic(Math.ceil(TS * .4) - 1, Math.ceil(TS * .4) - 1, colors[nextTetromino]);

					nextTetrominoShape.add(tile);
				}
			}
		}
	}

	private function placeTetromino():Void
	{
		tetromino.x = tCol * TS + tColOffset;
		tetromino.y = tRow * TS + tRowOffset;
	}

	private function canFit(row:Int, col:Int, side:Int):Bool // ελέγχει αν το τετρόνιμο χωράει στο playfield
	{
		for (i in 0...tetrominoes[currentTetromino][side].length)
		{
			for (j in 0...tetrominoes[currentTetromino][side][i].length)
			{
				if (tetrominoes[currentTetromino][side][i][j] == 1)
				{
					// out of left boundary
					if (col + j < 0)
					{
						return false;
					}
					// out of right boundary
					if (col + j > 9)
					{
						return false;
					}
					// out of bottom boundary
					if (row + i > 19)
					{
						return false;
					}
					// over another tetromino
					if (fieldArray[row + i][col + j] == 1)
					{
						return false;
					}
				}
			}
		}
		return true;
	}

	private function landTetromino():Void
	{
		var tile:FlxSprite;
		for (i in 0...tetrominoes[currentTetromino][currentRotation].length)
		{
			for (j in 0...tetrominoes[currentTetromino][currentRotation][i].length)
			{
				if (tetrominoes[currentTetromino][currentRotation][i][j] == 1)
				{
					tile = new FlxSprite(TS * (tCol + j) + tColOffset + 1, TS * (tRow + i) + tRowOffset + 1);

					tile.makeGraphic(TS - 1, TS - 1, colors[currentTetromino]);

					// landed.name = "r" + (tRow + i) + "c" + (tCol + j);
					fieldArray[tRow + i][tCol + j] = 1;
					add(tile);
					landed[tRow + i][tCol + j] = tile;
				}
			}
		}
		remove(tetromino);
		// timeCount.removeEventListener(TimerEvent.TIMER, onTime);
		// timeCount.stop();
		checkForLines();
	}

	private function checkForLines():Void
	{
		for (i in 0...20)
		{
			if (fieldArray[i].indexOf(0) == -1)
			{
				for (j in 0...10)
				{
					fieldArray[i][j] = 0;
					remove(landed[i][j]);
				}
				var j = i;

				while (j > 0)
				{
					j--;
					for (k in 0...10)
					{
						if (fieldArray[j][k] == 1)
						{
							fieldArray[j][k] = 0;
							fieldArray[j + 1][k] = 1;

							landed[j][k].y += TS;
							landed[(j + 1)][k] = landed[j][k];
							landed[j][k] = null;
						}
					}
				}
			}
		}
	}
}
