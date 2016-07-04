# Represents a single slot on the minesweeper board
class Cell
  attr_accessor :state, :has_mine, :has_flag, :clicked, :board
  attr_accessor :line_pos, :col_pos

  def initialize(line_pos, col_pos, board)
    @line_pos = line_pos
    @col_pos = col_pos
    @board = board

    # Valid states are: 'unknown', 'clear', 'flag' and 'bomb'
    @state = 'unknown'

    @has_mine = false
    @has_flag = false
    @clicked = false
  end

  def mines_nearby
    amount_nearby = 0

    neighbors.each do |neighbor|
      amount_nearby += 1 if neighbor.has_mine
    end

    amount_nearby
  end

  def deploy_mine
    self.has_mine = true
  end

  def neighbor_lines
    max_line = board.length
    [[line_pos - 1, 0].max, line_pos, [line_pos + 1, max_line - 1].min].uniq
  end

  def neighbor_cols
    max_col = board[0].length
    [[col_pos - 1, 0].max, col_pos, [col_pos + 1, max_col - 1].min].uniq
  end

  def neighbors
    all_neighbors = []

    line_values = neighbor_lines
    col_values = neighbor_cols

    positions = line_values.product(col_values)
    positions.delete_at(positions.index([line_pos, col_pos]))

    positions.each { |line, col| all_neighbors.push(board[line][col]) }

    all_neighbors.compact
  end

  def clear
    self.clicked = true
    self.state = 'clear'
  end

  def valid_neighbors
    queue = []
    neighbors.each do |neighbor|
      queue.push(neighbor) if neighbor.vaild_to_expand?
    end
    queue
  end

  def click
    raise 'Dead' if has_mine

    clear
    queue = (mines_nearby == 0) ? valid_neighbors : []

    queue.each do |element|
      element.clear
      next if element.mines_nearby > 0
      element.valid_neighbors.each { |neighbor| queue.push(neighbor) }
    end
    queue.uniq.length + 1
  end

  def vaild?(is_dead)
    !clicked && !has_flag && !is_dead
  end

  def vaild_to_expand?
    !clicked && !has_mine && !has_flag
  end

  def flag
    old_flag = has_flag
    self.has_flag = !self.has_flag unless clicked

    if old_flag && !has_flag && has_mine
      score_change = -1
    elsif !old_flag && has_flag && has_mine
      score_change = 1
    else
      score_change = 0
    end

    [!clicked, score_change]
  end
end

# Monitors the state of a single Minesweeper game
class Minesweeper
  attr_accessor :amount_discovered, :dead, :board
  attr_reader :num_lines, :num_cols, :num_mines

  def initialize(width, height, num_mines)
    if num_mines > width * height
      raise ArgumentError, 'There can\'t be more mines than slots on the board'
    end

    @num_lines = height
    @num_cols = width
    @num_mines = num_mines
    @amount_discovered = 0
    @dead = false

    start_board
  end

  def start_board
    @board = Array.new(num_lines) { Array.new(num_cols, Cell.new(0, 0, board)) }

    board.each_with_index do |line, line_pos|
      line.each_with_index do |_, col_pos|
        board[line_pos][col_pos] = Cell.new(line_pos, col_pos, board)
      end
    end

    mines_deployed = 0
    while mines_deployed < num_mines
      deploy_mine
      mines_deployed += 1
    end
  end

  def deploy_mine
    line_pos = rand(num_lines)
    col_pos = rand(num_cols)
    while board[line_pos][col_pos].has_mine
      line_pos = rand(num_lines)
      col_pos = rand(num_cols)
    end
    board[line_pos][col_pos].deploy_mine
  end

  def flag(line, col)
    val, score_change = board[line][col].flag
    self.amount_discovered += score_change
    val
  end

  def play(line, col)
    if still_playing?
      begin
        if board[line][col].vaild?(dead)
          self.amount_discovered += board[line][col].click
          true
        else
          false
        end
      rescue
        self.dead = true
        true
      end
    else
      false
    end
  end

  def still_playing?
    num_clean_slots = num_lines * num_cols - num_mines
    !dead && amount_discovered < num_clean_slots
  end

  def victory?
    !still_playing? && !dead
  end

  def board_state(options = {})
    board_repr = Array.new(num_lines) { Array.new(num_cols) }

    board_repr.each_with_index do |line, line_pos|
      line.each_with_index do |_, col_pos|
        cell = board[line_pos][col_pos]

        board_repr[line_pos][col_pos] = {
          has_flag: cell.has_flag,
          mines_nearby: cell.mines_nearby,
          state: cell.state
        }

        if !still_playing? && options[:xray]
          board_repr[line_pos][col_pos][:has_mine] = cell.has_mine
        end
      end
    end
  end
end

# Simple printer for minesweeper board representation
class SimplePrinter
  def print_element(element)
    if element[:has_mine]
      print '# '
    elsif element[:has_flag]
      print 'F '
    elsif element[:state] == 'unknown'
      print '. '
    elsif element[:mines_nearby] > 0
      print "#{element[:mines_nearby]} "
    else
      print 'D '
    end
  end

  def custom_print(board)
    printed = 0
    while printed < board.length
      board[printed].each do |element|
        print_element(element)
      end
      print "\n"
      printed += 1
    end
  end
end

# Cute printer for minesweeper board representation
class PrettyPrinter
  def print_element(element)
    if element[:has_mine]
      print '# '
    elsif element[:has_flag]
      print 'F '
    elsif element[:mines_nearby] > 0 && element[:state] == 'clear'
      print "#{element[:mines_nearby]} "
    elsif element[:state] == 'clear'
      print 'D '
    else
      print '. '
    end
  end

  def custom_print(board)
    printed = 0
    print '+ '
    print '-' * board[0].length * 2 + ' +'
    print "\n"
    while printed < board.length
      print '| '
      board[printed].each do |element|
        print_element(element)
      end
      print " |\n"
      printed += 1
    end
    print '+ '
    print '-' * board[0].length * 2 + ' +'
    print "\n"
  end
end
