/// Lab 4
// Zach Johnston
// CS 145
// Blackjack:
// Each round the user is given 2 cards. The value of those card is added up
// Your goal is to get as close to 21 without having greater then 21
// The user is asked if they want another card after getting the 2 Cards
// They will be given more cards until they stop or bust
// if they go over 21 then end the game
// Otherwise tell the player what the dealer has
// Total up both the player and dealer and compare score
// If they player is under or equal to 21 and is greater then dealer then print win
// Otherwise print that you lost
import java.util.*;
import java.lang.Math;
class Blackjack {

    public static void main(String argv[]) {

		Scanner UserInput = new Scanner(System.in);

		Random CardGen = new Random(); // Random Cards

		int Playerscore; // Player Total Card Value
		int Dealerscore; // Dealer Total Card Value
	
		System.out.println("Welcome to Blackjack!");
	    System.out.println("In order to win the game get as close to 21.");
	    System.out.println("You will be given two cards and are trying to beat the dealer.");
	    System.out.println("You can draw as many cards as you want but do not go over 21.");
	    System.out.println("Good luck!\n");
	    	System.out.println("================================");
		// Prints the player's final score
		Playerscore = PlayerGame(UserInput, CardGen);
		System.out.println("Your final total score is " + Playerscore);

		// Print Dealers final score.
		Dealerscore = playDealer(CardGen);
		System.out.println("The dealers total score is " + Playerscore);

		WinCon(Playerscore, Dealerscore);
    }

    // Method for player drawing cards
    public static int PlayerGame(Scanner UserInput, Random r) {
        //Sees if player would like to hit
		boolean Playerhit = true;
		// Keeps track of user cards
		int Usercards = 0; 
		// Keeps track of the value of player card
		int Playerscore = 0;

		// Loop till player doesn't want to hit or they bust
		while (Playerhit) {

	    	int card = 0; 

	    	// Give player 2 cards at start then 1 card
	    	while (Usercards < 2 || card < 1) {
                    // Random Card
				int randNum = Math.abs(r.nextInt())%13; 

				// If ACE then let user pick card value of 1 or 11
				if (randNum == 0) {
		    		Playerscore = Playerscore + PlayerAce(UserInput);
				}

				// Scores Player value
				else if (randNum < 10) {
		    		System.out.println("Your card value is " + (randNum + 1));
		    		Playerscore = Playerscore + randNum + 1;
				}
				else {
		    		System.out.println("Your card value is 10");
		    		Playerscore = Playerscore + 10;
				}

				// Increment the cards up
			    Usercards++;
				card++;
	    	}	

	    	// Prints out player current score 
	    	// Input user for if they want another hit
	    	
	    	System.out.println("So, your current score is " + Playerscore);
	    		System.out.println("================================");
	    		//Check value if they do not have 21 or greater
	    	if (Playerscore <= 21) {
	    		
				System.out.println("Would you like to hit again?");
				char ans = (UserInput.next()).charAt(0);
		
				if (ans != 'y' && ans != 'Y')
		    	    Playerhit = false; 
		    		// Set Hit to false
	    	}
	    	else
				Playerhit = false;
		}	

		return Playerscore;

    }

    // Give dealer their cards
    public static int playDealer(Random r) {

        int Dealerscore = 0;

		// Dealer hits until 17
		while (Dealerscore < 17) {
            // Random Card
	    	int randNum = Math.abs(r.nextInt())%13; 
	    	// Scores dealer total value for cards
	    	int cardTotal; 

	    	// Picks the ace value that is best
	    	if (randNum == 0) {
		
				if (Dealerscore < 11) 
		    		cardTotal = 11;
				else 
		    		cardTotal = 1;
	    	}
	    	else if (randNum < 10) 
				cardTotal = randNum + 1;
	    	else 
				cardTotal = 10;

	    	// Prints out dealer score
	    	Dealerscore = Dealerscore + cardTotal;
	    	System.out.println("Dealer card value is " + cardTotal);
		}

		return Dealerscore;
    }

// Prints out both the player and dealer score
// Then figures out who wins the game
    public static void WinCon(int playerTotal, int DealerTotal) {
            	System.out.println("================================");
		// Prints out winner 
		if (playerTotal > 21 && DealerTotal > 21)
	    	System.out.println("Both of us Busted. No one wins!");
		else if (playerTotal > 21)
	    	System.out.println("You have busted. Dealer wins!");
		else if (DealerTotal > 21)
	    	System.out.println("Dealer busted. You win!");
		else {
	    
	    	if (playerTotal > DealerTotal)
				System.out.println("You won!!!");
	    	else if (playerTotal < DealerTotal)
				System.out.println("You beat the Dealer!");
	    	else
				System.out.println("We have tied.");
		}	

    }

    // If a player gets an ace
    // Pick the value of the card
    public static int PlayerAce(Scanner UserInput) {

  		System.out.println("You have gotten an ace, would you like it to count as 11 or 1.");
		int acevalue = UserInput.nextInt();
	
		// Prompt user until correct value is entered
		while (acevalue != 11 && acevalue != 1) {

        	System.out.println("Sorry, that is not valid, please enter either 1 or 11");	
           	acevalue = UserInput.nextInt();
		}

		return acevalue;
    }

}