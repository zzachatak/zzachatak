// Zach Johnston
// CS 145 
// Guessing
// This game allows the user to input a number and try and guess a random number
// After they guess it will tell them higher or lower
// Then when they guess the number the user will input if they want to play again
// If yes create a new random number
// If no then print the stats
import java.util.Random; // Allows random var
import java.util.Scanner; // User input

public class GuessingGame {

public static void main(String[] args) {

//stores the user choice for each game
String Userchoice = null;
int totalgames = 0; // Total amount of games the user has played
int totalguess= 0; // Total number of guesser the user has for that game
double AVGguess = 0; // The number of guess in a game
int bestgame = 0; // The lowest guesses for games played
int bestguess = 0; // The least amount of guesses
int num = 0; // Create an int for a random number to be stored
int guess=0; // The user guess is stored in here
boolean Playgame=true; // When true play the game
Scanner scan=new Scanner(System.in); // User input
Random rand=new Random(); // Random Number
// Display the rules of the game
System.out.println("This program allows you to play a guessing game.\nI will think of a number between 1 and 100\nand will allow you to guess until \nyou get it. For each guess, I will tell you \nwhether the right answer is higher or lower\nthan your guess.\n\n");
// Loop the game
do
{
//Display text
System.out.println("\nI'm thinking of a number between 1 and 100...");
totalgames+=1; //increase the total games played by 1
num=rand.nextInt(100)+1; //generate random number 
Playgame=true; // Playgame is true so don't end the game
AVGguess=0; // Game guess set to 0
//loop till Playgame is false
while(Playgame)
{
//Take user input on their guess
System.out.print("Your guess? ");
// Input the users input into guess
guess=scan.nextInt();
//if user guess is less then number print higher
if(guess<num)
{
System.out.println("It's higher.");
AVGguess++; //increase guess amount
}
//if user guess is higher then number print lower
else if(guess>num)
{
System.out.println("It's lower.");
AVGguess++;//increase guess amount
}
else
{
//increase guess amount
AVGguess++;
//Fist try on guessing
if(AVGguess==1)
System.out.println("You got it right in 1 guess!");
//if it takes more then one guess
else
System.out.println("You got it right in "+AVGguess+" guesses!");
//Set Play game is false
Playgame=false;
}

}
//add the guesses to the total amount of guesses
totalguess+=AVGguess;
//if bestguess is 0 then it was the first game
if (bestguess==0)
{
//bestgame will be printed as first game
bestgame=totalgames;
//bestguesses will be number of guesses in this first game
bestguess=(int)AVGguess;
}
//However if the guess is lower then bestgame
else if(AVGguess<bestguess)
{
//bestgame will be the current game
bestgame=totalgames;
//bestguesses will display the current game guesses
bestguess=(int)AVGguess;
}
//User will input if they want to play again
System.out.print("Do you want to play again? ");
//Input user into scanner
Userchoice=scan.next();
//convert to lowercase allowing both y and Y
Userchoice=Userchoice.toLowerCase();
//The game will end if they do not pick Y or y
}while(Userchoice.equalsIgnoreCase("y"));

//calc guess each game
AVGguess=(double)totalguess/totalgames;
String str=String.format("%.1f",AVGguess);
//printing game results
System.out.println("\nOverall results:\n");
System.out.println("\nTotal games = "+totalgames);
System.out.println("\nTotal guesses = "+totalguess);
System.out.println("\nGuesses/game = "+str);
System.out.println("\nBest game = "+bestgame);
}

}
