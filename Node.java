//Zach Johnston
//145
// Using the class to store the information of first Name
// lastName address city and mobile phone
public class Node {
    private String Location;
    private String lastName;
    private String phone;
    private String add;
    private String Name;
    
    //The constructor for parameterised 
    public Node(String Name, String lastName, String add, String Location, String phone) {
        this.mobile = phone;
        this.Name = Name;
        this.lastName = lastName;
        this.Location = add;
        this.city = Location;
       
    }

    @Override
    public String toString() {
        return "Full Name: '" + firstName + " " + lastName + '\'' +
                ", Address: '" + address + '\'' +
                ", City: '" + city + '\'' +
                ", Mobile: '" + mobile + '\'';
    }
    //Used to get the name
    public String getFirstName() {
        return Name;
    }
    //Used to get the lastName
    public String getLastName() {
        return lastName;
    }
    //Used to set the name
    public void setFirstName(String firstName) {
        this.Name = Name;
    }
    //Used to set the lastName
    public void setLastName(String lastName) {
        this.lastName = lastName;
    }
    //Used to get the address
    public String getAddress() {
        return add;
    }
    //Used to set the address
    public void setAddress(String add) {
        this.add = add;
    }
    //Used to get the city
    public String getCity() {
        return Location;
    }
    //Used to set the city
    public void setCity(String Location) {
        this.Location = Location;
    }
   // Used to get the mobile phone
    public String getMobile() {
        return phone;
    }
    //Setter for mobile
    public void setMobile(String phone) {
        this.phone = phone;
    }
}