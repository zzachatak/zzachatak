//Zach Johnston
//145
// This class is ued to take the information of the Name,lastName,address, city and PhoneBookManage
// We then are storing these entrys in link LinkedList
// We are also able to access this information
// You can add and remove contacts from the PhoneBookManager

import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedList;

public class PhoneBookManager {
    private LinkedList<Node> phoneBook;

// Creates an empty phoneBook.
    PhoneBookManager() {
        this.phoneBook = new LinkedList<>();
    }

// Add new information into the phoneBook
    public boolean addNewEntry(String Name, String lastName, String add, String Location, String phone) {
        return this.phoneBook.add(new Node(Name, lastName, add, Location, phone));
    }

 
// This function will modify the information given a first name and change that value
    public void modifyEntry(String Name, String num, int info) {
        for(Node bookInfo: this.phoneBook) {
            if(bookInfo.getFirstName().equals(Name)) {
                if(info == 1) bookInfo.setFirstName(num);
                else if(info == 2) bookInfo.setLastName(num);
                else if(info == 3) bookInfo.setAddress(num);
                else if(info == 4) bookInfo.setMobile(num);
                else if(info == 5) bookInfo.setCity(num);
                else {
                    System.out.println("Wrong Value!");
                    return;
                }

                System.out.println("Entry Successfully!");
                return;
            }
        }
        System.out.println("User Couldn't Be Found!");
    }

    
//This function will delete the information in phoneBook. When you give it a Name

    public void deleteEntry(String Name) {
        for(Node bookInfo: this.phoneBook) {
            if(bookInfo.getFirstName().equals(Name)){
                this.phoneBook.remove(bookInfo);
                System.out.println("Entry has been deleted!");
                return;
            }
        }
        System.out.println("User Couldn't Be Found!");
    }

//This function displays the information for phonebook
    public void displayPhoneBook() {
        for(Node bookInfo: this.phoneBook) {
            System.out.println(bookInfo.toString());
        }
        System.out.println();
        System.out.println();
    }

// This function will sort the phonebook so it is based on entries with lastname
    public void sortPhoneBookByLastName() {
        Collections.sort(this.phoneBook, new Comparator<Node>() {
            @Override
            public int compare(Node num1, Node num2) {
                return num1.getLastName().compareTo(num2.getLastName());
            }
        });
    }
}