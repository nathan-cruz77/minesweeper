require 'test/unit'
require_relative 'minesweeper'

# Minesweeper tests
class MinesweeperTest < Test::Unit::TestCase
  def test_initialize
    assert_raise(ArgumentError) { Minesweeper.new(10, 10, 101) }
    assert_raise(ArgumentError) { Minesweeper.new(-1, 10, 5) }
    assert_raise(ArgumentError) { Minesweeper.new(-5, -10, 1) }
    assert_raise(TypeError) { Minesweeper.new('lizard', 10, 1) }
    assert_raise(TypeError) { Minesweeper.new(10, 'lizard', 1) }
    assert_raise(TypeError) { Minesweeper.new(10, 10, '001001001') }
    assert_nothing_raised { Minesweeper.new(2, 4, 3) }

    game = Minesweeper.new(2, 4, 3)
    assert_equal(4, game.num_lines)
    assert_equal(2, game.num_cols)
    assert_equal(3, game.num_mines)
    assert_equal(0, game.amount_discovered)
    assert(!game.dead)
  end

  def test_start_board
    game = Minesweeper.new(10, 10, 1)
    mines, _ = find_mine(game)
    assert_equal(1, mines)

    game = Minesweeper.new(10, 10, 50)
    mines, _ = find_mine(game)
    assert_equal(50, mines)

    game = Minesweeper.new(10, 10, 99)
    mines, _ = find_mine(game)
    assert_equal(99, mines)

    game = Minesweeper.new(10, 1, 1)
    mines, _ = find_mine(game)
    assert_equal(1, mines)

    game = Minesweeper.new(10, 1, 5)
    mines, _ = find_mine(game)
    assert_equal(5, mines)

    game = Minesweeper.new(10, 1, 9)
    mines, _ = find_mine(game)
    assert_equal(9, mines)

    game = Minesweeper.new(1, 10, 1)
    mines, _ = find_mine(game)
    assert_equal(1, mines)

    game = Minesweeper.new(1, 10, 5)
    mines, _ = find_mine(game)
    assert_equal(5, mines)

    game = Minesweeper.new(1, 10, 9)
    mines, _ = find_mine(game)
    assert_equal(9, mines)
  end

  def test_deploy_mine
    game = Minesweeper.new(10, 10, 1)
    mines, cell = find_mine(game)
    assert_equal(1, mines)
    assert(cell.has_mine)

    game.deploy_mine
    mines, cell = find_mine(game)
    assert_equal(2, mines)
    assert(cell.has_mine)
  end

  def test_flag
    game = Minesweeper.new(10, 10, 1)
    res = game.flag(1, 2)
    assert(game.board[1][2].has_flag)
    assert(res)

    game = Minesweeper.new(10, 10, 1)
    game.board[1][1].clicked = true
    game.board[1][1].state = 'clear'
    res = game.flag(1, 1)
    assert(!res)
    assert(!game.board[1][1].has_flag)
  end

  def test_still_playing?
    game = Minesweeper.new(10, 10, 1)
    assert(game.still_playing?)

    game = Minesweeper.new(10, 10, 1)
    game.dead = true
    assert(!game.still_playing?)

    game = Minesweeper.new(10, 10, 1)
    game.amount_discovered = 100
    assert(!game.still_playing?)
  end

  def test_play
    game = Minesweeper.new(10, 10, 0)
    res = game.play(0, 1)
    assert(res)

    game = Minesweeper.new(10, 10, 0)
    game.dead = true
    res = game.play(1, 2)
    assert(!res)

    game = Minesweeper.new(10, 10, 0)
    game.board[1][2].deploy_mine
    res = game.play(1, 2)
    assert(res)

    game = Minesweeper.new(10, 10, 0)
    game.flag(2, 1)
    res = game.play(2, 1)
    assert(!res)
  end

  def test_victory?
    game = Minesweeper.new(10, 10, 0)
    game.play(0, 5)
    assert(game.victory?)

    game = Minesweeper.new(10, 10, 1)
    _, cell = find_mine(game)
    game.play(cell.line_pos, cell.col_pos)
    assert(!game.victory?)
  end

  def test_board_state
    game = Minesweeper.new(10, 10, 1)
    game.flag(1, 1)
    assert(game.board_state[1][1][:has_flag])

    game = Minesweeper.new(10, 10, 0)
    game.board[2][2].deploy_mine
    assert_equal(1, game.board_state[1][2][:mines_nearby])

    game = Minesweeper.new(10, 10, 0)
    assert_equal('unknown', game.board_state[2][5][:state])

    game = Minesweeper.new(10, 10, 0)
    game.board[5][5].deploy_mine
    game.dead = true
    assert(game.board_state(xray: true)[5][5][:has_mine])
  end

  def find_mine(game)
    mines = 0
    cell_mine = nil
    game.board.each do |line|
      line.each do |cell|
        if cell.has_mine
          mines += 1
          cell_mine = cell
        end
      end
    end
    [mines, cell_mine]
  end
end

# Minesweeper board cell tests
class CellTest < Test::Unit::TestCase
  def test_initialize
    assert_nothing_raised { Cell.new(10, 10, nil) }
    assert_raise(ArgumentError) { Cell.new(-1, 10, nil) }
    assert_raise(ArgumentError) { Cell.new(-5, -10, nil) }
    assert_raise(TypeError) { Cell.new('lizard', 10, nil) }
    assert_raise(TypeError) { Cell.new(10, 'lizard', nil) }
    assert_nothing_raised { Cell.new(10, 10, nil) }
    assert_nothing_raised { Cell.new(2, 4, nil) }
  end

  def test_mines_nearby
    game = Minesweeper.new(10, 10, 0)
    assert_equal(0, game.board[1][1].mines_nearby)

    game = Minesweeper.new(10, 10, 0)
    game.board[1][2].deploy_mine
    assert_equal(1, game.board[1][1].mines_nearby)

    game = Minesweeper.new(10, 10, 0)
    game.board[2][5].deploy_mine
    game.board[1][5].deploy_mine
    game.board[1][7].deploy_mine
    assert_equal(3, game.board[2][6].mines_nearby)
  end

  def test_clear
    game = Minesweeper.new(10, 10, 3)
    game.board[2][3].clear
    game.board[3][4].clear
    assert_equal('clear', game.board[2][3].state)
    assert_equal(true, game.board[2][3].clicked)
    assert_equal('clear', game.board[3][4].state)
    assert_equal(true, game.board[3][4].clicked)
  end

  def test_neighbor_lines
    game = Minesweeper.new(10, 10, 1)
    res = game.board[0][0].neighbor_lines
    expected = [0, 1]
    assert_equal(expected, res)

    game = Minesweeper.new(10, 10, 1)
    res = game.board[9][9].neighbor_lines
    expected = [8, 9]
    assert_equal(expected, res)

    game = Minesweeper.new(10, 10, 1)
    res = game.board[5][5].neighbor_lines
    expected = [4, 5, 6]
    assert_equal(expected, res)
  end

  def test_neighbor_cols
    game = Minesweeper.new(10, 10, 1)
    res = game.board[0][0].neighbor_cols
    expected = [0, 1]
    assert_equal(expected, res)

    game = Minesweeper.new(10, 10, 1)
    res = game.board[9][9].neighbor_cols
    expected = [8, 9]
    assert_equal(expected, res)

    game = Minesweeper.new(10, 10, 1)
    res = game.board[5][5].neighbor_cols
    expected = [4, 5, 6]
    assert_equal(expected, res)
  end

  def test_valid?
    game = Minesweeper.new(10, 10, 1)
    assert(game.board[2][1].valid?(false))

    game = Minesweeper.new(10, 10, 1)
    game.board[1][1].clicked = true
    game.board[1][1].state = 'clear'
    assert(!game.board[1][1].valid?(false))

    game = Minesweeper.new(10, 10, 1)
    assert(!game.board[5][6].valid?(true))

    game = Minesweeper.new(10, 10, 1)
    game.flag(5, 6)
    assert(!game.board[5][6].valid?(false))
  end

  def test_valid_to_expand?
    game = Minesweeper.new(10, 10, 0)
    assert(game.board[2][1].valid_to_expand?)

    game = Minesweeper.new(10, 10, 1)
    game.board[1][1].clicked = true
    game.board[1][1].state = 'clear'
    assert(!game.board[1][1].valid_to_expand?)

    game = Minesweeper.new(10, 10, 1)
    game.flag(5, 6)
    assert(!game.board[5][6].valid_to_expand?)

    game = Minesweeper.new(10, 10, 0)
    game.board[5][6].deploy_mine
    assert(!game.board[5][6].valid_to_expand?)
  end

  def test_valid_neighbors
    game = Minesweeper.new(15, 15, 0)
    game.board[3][2].deploy_mine
    res = game.board[0][0].valid_neighbors
    expected = [game.board[0][1], game.board[1][0], game.board[1][1]]
    assert_equal(expected, res)

    game = Minesweeper.new(10, 10, 0)
    game.board[0][1].deploy_mine
    game.board[1][1].deploy_mine
    game.board[1][0].deploy_mine
    res = game.board[0][0].valid_neighbors
    expected = []
    assert_equal(expected, res)
  end

  def test_neighbors
    game = Minesweeper.new(10, 10, 1)
    res = game.board[9][9].neighbors
    expected = [game.board[8][8], game.board[8][9], game.board[9][8]]
    assert_equal(expected, res)

    game = Minesweeper.new(10, 10, 1)
    res = game.board[0][0].neighbors
    expected = [game.board[0][1], game.board[1][0], game.board[1][1]]
    assert_equal(expected, res)

    game = Minesweeper.new(10, 10, 1)
    res = game.board[5][5].neighbors
    expected = [game.board[4][4], game.board[4][5], game.board[4][6],
                game.board[5][4], game.board[5][6], game.board[6][4],
                game.board[6][5], game.board[6][6]]
    assert_equal(expected, res)
  end

  def test_deploy_mine
    game = Minesweeper.new(10, 10, 0)
    game.board[1][3].deploy_mine
    assert(game.board[1][3].has_mine)
  end

  def test_click
    game = Minesweeper.new(10, 10, 0)
    game.board[3][3].deploy_mine
    assert_equal(99, game.board[1][1].click)

    game = Minesweeper.new(10, 10, 1)
    _, cell = find_mine(game)
    assert_raise(RuntimeError) { cell.click }

    game = Minesweeper.new(10, 10, 0)
    game.board[3][3].deploy_mine
    assert_equal(1, game.board[2][3].click)
  end

  def test_flag
    game = Minesweeper.new(10, 10, 1)
    assert(game.board[3][9].flag)

    game = Minesweeper.new(10, 10, 1)
    game.board[0][7].clear
    assert(!game.board[0][7].flag)
  end

  def find_mine(game)
    mines = 0
    cell_mine = nil
    game.board.each do |line|
      line.each do |cell|
        if cell.has_mine
          mines += 1
          cell_mine = cell
        end
      end
    end
    [mines, cell_mine]
  end
end
