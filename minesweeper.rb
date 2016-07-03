
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
    if self.state == 'unknown'
      raise 'Unable to check amount of mines nearby. Cell is not clear.'
    end

    amount_nearby = 0

    self.neighbors.each do |neighbor|
      if neighbor.has_mine
        amount_nearby += 1
      end
    end

    amount_nearby

  end

  def deploy_mine
    self.has_mine = true
  end

  def neighbors
    all_neighbors = []

    max_line, max_col = self.board.length, self.board[0].length

    line_values = [
      [self.line_pos - 1, 0].max,
      self.line_pos,
      [self.line_pos + 1, max_line - 1].min
    ]

    col_values = [
      [self.col_pos - 1, 0].max,
      self.col_pos,
      [self.col_pos + 1, max_col - 1].min
    ]

    line_values.uniq!
    col_values.uniq!

    positions = line_values.product(col_values)
    positions.delete_at(positions.index([self.line_pos, self.col_pos]))

    positions.each do |line_value, col_value|
      all_neighbors.push(self.board[line_value][col_value])
    end

    all_neighbors.compact
  end

  def click
    # puts "Clicking [#{self.line_pos}, #{self.col_pos}]"
    if self.has_mine
      raise 'Dead'
    end

    self.clicked = true
    self.state = 'clear'

    new_discovered = 1
    queue = []

    # print "Vizinhos: "
    # self.neighbors.each {|l| puts "\t[#{l.line_pos}, #{l.col_pos}]"}

    if self.mines_nearby == 0
      self.neighbors.each do |neighbor|
        if neighbor.is_valid_to_expand?
          queue.push(neighbor)
        end
      end
    end

    queue.each do |element|

      element.clicked = true
      element.state = 'clear'
      new_discovered += 1

      if element.mines_nearby == 0
        element.neighbors.each do |neighbor|
          if neighbor.is_valid_to_expand?
            queue.push(neighbor)
          end
        end
      end
    end

    queue.uniq.length + 1
  end

  def is_valid?(is_dead)
    !self.clicked and !self.has_flag and !is_dead
  end

  def is_valid_to_expand?
    !self.clicked and !self.has_mine and !self.has_flag
  end

  def flag
    if !self.clicked
      self.has_flag = !self.has_flag
    end

    !self.clicked
  end

  def to_s(xray=false)
    if xray and self.has_mine
      return '#'
    elsif self.has_flag
      return 'F'
    elsif self.state == 'unknown'
      return '.'
    elsif self.mines_nearby == 0
      return '*'
    else
      return "#{self.mines_nearby}"
    end
  end

end


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

    self.start_board
  end

  def start_board
    @board = Array.new(self.num_lines) { Array.new(self.num_cols, Cell.new(0, 0, self.board)) }

    self.board.each_with_index do |line, line_pos|
      line.each_with_index do |element, col_pos|
        self.board[line_pos][col_pos] = Cell.new(line_pos, col_pos, self.board)
      end
    end

    mines_deployed = 0
    while mines_deployed < self.num_mines
      self.deploy_mine
      mines_deployed += 1
    end

  end

  def deploy_mine
    line_pos, col_pos = rand(self.num_lines), rand(self.num_cols)
    while self.board[line_pos][col_pos].has_mine
      line_pos, col_pos = rand(self.num_lines), rand(self.num_cols)
    end
    self.board[line_pos][col_pos].deploy_mine
  end

  def flag(line, col)
    self.board[line][col].flag
  end

  def play(line, col)
    # puts "CLICANDO EM (#{line}, #{col})"
    if self.still_playing?
      begin
        if self.board[line][col].is_valid?(self.dead)
          self.amount_discovered += self.board[line][col].click
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
    num_clean_slots = self.num_lines * self.num_cols - self.num_mines
    !self.dead and self.amount_discovered < num_clean_slots
  end

  def victory?
    self.still_playing? and !self.dead
  end

  def board_state(options = {})
    return self.board
    board_repr = Array.new(self.num_lines){ Array.new(self.num_cols, '') }

    board_repr.each_with_index do |line, line_pos|
      line.each_with_index do |element, col_pos|
        board_repr[line_pos][col_pos] = self.board[line_pos][col_pos].to_s
      end
    end

  end

end


class SimplePrinter

  def custom_print(board)
    printed = 0
    while printed < board.length
      board[printed].each do |element|
        if element.has_mine
          print "B "
        elsif element.has_flag
          print "F "
        else
          print element.state[0] + " "
        end
      end
      print "\n"
      printed += 1
    end
  end

end


class PrettyPrinter

  def custom_print(board)
    printed = 0
    while printed < board.length
      board[printed].each do |element|
        if element.has_mine
          print "B "
        elsif element.has_flag
          print "F "
        else
          print element.state[0] + " "
        end
      end
      print "\n"
      printed += 1
    end
  end

end

# This has to work!
width, height, num_mines = 10, 5, 3
game = Minesweeper.new(width, height, num_mines)

while game.still_playing?
  valid_move = game.play(rand(height), rand(width))
  valid_flag = game.flag(rand(height), rand(width))
  if valid_move or valid_flag
    printer = (rand > 0.5) ? SimplePrinter.new : PrettyPrinter.new
    printer.custom_print(game.board_state)
    puts
  end
end

puts "Fim do jogo!"
if game.victory?
  puts "Você venceu!"
else
  puts "Você perdeu! As minas eram:"
  PrettyPrinter.new.custom_print(game.board_state(xray: true))
end
