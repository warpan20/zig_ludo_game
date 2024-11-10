const std = @import("std");
var rand_impl = std.rand.DefaultPrng.init(42);

const MAX_PLAYERS = 4;
const PIECES_PER_PLAYER = 1; // this code only works for one piece, need to adjust the logic for multiple pieces
const BOARD_SIZE = 10;
const WINNING_POSITION = 0; // Define the winning position on the board

const PlayerColor = enum {
    Red,
    Green,
    Yellow,
    Blue,
};

// GameState now includes the active player and the dice roll, making it clear if movement is possible.
const GameState = struct {
    player_index: usize,
    phase: Phase,
    dice_roll: i32 = undefined, // Store dice roll to use in both phases

    const Phase = enum {
        Rolling,
        Moving,
        Waiting,
    };
};

const Piece = struct {
    position: i32,
    at_home: bool,

    fn new() Piece {
        return Piece{ .position = -1, .at_home = true };
    }
};

const Player = struct {
    color: PlayerColor,
    pieces: [PIECES_PER_PLAYER]Piece,

    fn new(color: PlayerColor) Player {
        var pieces: [PIECES_PER_PLAYER]Piece = undefined;
        for (&pieces) |*piece| {
            piece.position = 0; // Modify the piece itself
        }
        return Player{ .color = color, .pieces = pieces };
    }

    fn can_move(self: *Player, dice_roll: i32) bool {
        // Check if any piece can move given the dice roll
        for (self.pieces) |piece| {
            if (piece.position == -1 and dice_roll == 6) {
                return true; // Can move piece out of home with a roll of 6
            } else if (piece.position != -1) {
                return true; // Can move any piece already on the board
            }
        }
        return false;
    }

    fn move_piece(self: *Player, dice_roll: i32) void {
        // Basic logic to move a piece based on the dice roll
        for (&self.pieces) |*piece| {
            if (piece.position == -1 and dice_roll == 6) {
                piece.position = 0; // Move piece out of home
                piece.at_home = false;
                break;
            } else if (piece.position != -1) {
                piece.position += dice_roll;
                piece.position = @mod(piece.position, BOARD_SIZE); // Wrap around the board
                break;
            }
        }
    }

    fn has_won(self: *Player) bool {
        // Check if all pieces of the player have reached the winning position
        for (self.pieces) |piece| {
            if (piece.position != WINNING_POSITION) {
                return false;
            }
        }
        return true;
    }
};

pub fn main() void {
    var players = [_]Player{
        Player.new(PlayerColor.Red),
        Player.new(PlayerColor.Green),
        Player.new(PlayerColor.Yellow),
        Player.new(PlayerColor.Blue),
    };
    var game_state = GameState{
        .player_index = 0,
        .phase = GameState.Phase.Waiting,
        .dice_roll = 0, // Initialize dice_roll to 0
    };

    while (true) {
        var current_player = &players[game_state.player_index];

        switch (game_state.phase) {
            GameState.Phase.Waiting => {
                std.debug.print("Player {}'s turn\n", .{current_player.color});
                game_state.dice_roll = 0; // Reset dice_roll to 0 during the Waiting phase
                game_state.phase = GameState.Phase.Rolling;
            },
            GameState.Phase.Rolling => {
                game_state.dice_roll = roll_dice();
                std.debug.print("Player {} rolled: {}\n", .{current_player.color, game_state.dice_roll});
                
                // Decide if player can move based on the roll
                if (current_player.can_move(game_state.dice_roll)) {
                    game_state.phase = GameState.Phase.Moving;
                } else {
                    std.debug.print("Player {} has no moves\n", .{current_player.color});
                    next_turn(&game_state);
                }
            },
            GameState.Phase.Moving => {
                current_player.move_piece(game_state.dice_roll);
                std.debug.print("Player {} moved a piece\n", .{current_player.color});
                
                // Check if the current player has won
                if (current_player.has_won()) {
                    std.debug.print("Player {} wins!\n", .{current_player.color});
                    return; // End the game
                }

                next_turn(&game_state);
            },
        }
    }
}

fn roll_dice() i32 {
    const mod_int: u32 = 5;
    return @mod(rand_impl.random().int(i32), mod_int) + 1;
}

fn next_turn(game_state: *GameState) void {
    game_state.player_index = (game_state.player_index + 1) % MAX_PLAYERS;
    game_state.phase = GameState.Phase.Waiting;
    game_state.dice_roll = 0; // Reset dice_roll when switching to the waiting phase
}
