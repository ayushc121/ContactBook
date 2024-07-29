#!/bin/bash

PS3="Enter your selection: "            
#set the default prompt for user input
file=$1                                 
#saving the first argument when this script is run as a variable 

#defining the functions to be used in the program

search_entry() {
    
  echo -en "Contact to search for: "
  read search
  n=$(grep -i "$search" "$file" | wc -l | awk '{ print $1 }')
  
  if [ -z "$n" ]; then
    n=0
  fi
#finding if there were zero matches

  while [ "${n}" -ne "1" ]; do
    echo -en "${n} matches found. Please choose a "
    case "$n" in 
      "0") echo "less" ;;
      *) echo "more" ;;
    esac
#if zero matches, ask for less specific search term...if more than 1 match, ask for more specific search term

    echo "specific search term (press q to return to the selection menu): "
    read search
    if [ "$search" == "q" ]; then
      return 0
    fi
#giving users the option to exit searching if their search was unsuccessful
    
    n=$(grep -i "$search" "$file" | wc -l | awk '{ print $1 }')
  done
  
  return $(grep -in "$search" "$file" | cut -d":" -f1)
#the function outputs a string of the successful search
}



do_list() {
    
    echo -en "Press Enter to list the whole contact list, or search for: "
    read search
    if [ -z "$search" ]; then
        list=$(cat "$file")
#setting the list variable equal to the entire contact list if the user presses enter

    else
        list=$(grep -i "${search}" "$file")
#if the user searches for some string, any entries in the contacts list that match the string are saved in the variable
        
        res=$?
        if [ $res -ne 0 ]; then
            echo "No matches found."; echo
            return $res
        fi
#handling cases where the user enters something that is not present in the contact list
    fi

    echo "$list" | \
#preparing the list variable to be modified by sed 

    sed 's/, /#####/g' | \
#replacing all the comma-space with a placeholder

#awk interprets the csv using commas as delimiters

    awk -F ',' '
        BEGIN {print "\nContacts:\n---------"}
        {for (i = 1; i <= NF; i++) {gsub("#####", ", ", $i)}}
#replacing the placeholders back into commas

        {print $1,";", $2, $3, "\n", $4, "\n", $5,",", $6,",", $7,",", $8, $9, "\n", $10, "\n", $11, "\n";}
#printing formatted output of the list variable

        END {print "------------\nEnd of list.\n"}'
}



do_add() {

  echo "Enter the following information for the new contact:"
  echo "Contact number, First Name, Last Name, Company, Address, City, County, State, ZIP Code, Phone Number, and Email."; echo

#giving a prompt to the user

  echo -en "Contact number: "
    read contactnum
  echo -en "First Name: "
    read firstname
  echo -en "Last Name: "
    read lastname
  echo -en "Company: "
    read company
  echo -en "Address: "
    read address
  echo -en "City: "
    read city
  echo -en "County: "
    read county
  echo -en "State (abbreviated): "
    read state
  echo -en "ZIP Code: "
    read zipcode
  echo -en "Phone Number: "
    read phone
  echo -en "Email Address: "
    read email
#series of prompts for the user to enter information
  
  echo "${contactnum},${firstname},${lastname},${company},${address},${city},${county},${state},${zipcode},${phone},${email}" >> $file
  echo "Contact added to $file"; echo
#after the user enters everything, the information is added to the end of the contacts file and a confirmation message is displayed

}



do_remove() {
    
  search_entry
  search=`head -$? $file | tail -1`
#setting a variable equal to the return value of the search_entry function
#this variable will be null if the search_entry function did not find an entry

  if [ -z "${search}" ]; then
	return
  fi
#stopping function if search is null


  echo "This entry will be removed:"; echo

  echo "$search" | \
  sed 's/, /#####/g' | \
  awk -F ',' '   
       	{for (i = 1; i <= NF; i++) 
    			{gsub("#####", ", ", $i)}
    	} 
    	{print $1,";", $2, $3, "\n", $4, "\n", $5,",", $6,",", $7,",", $8, $9, "\n", $10, "\n", $11, "\n";}' 
#same logic as do_list but simplified to print only one item

  echo -en "Enter 'Y' to remove this entry or any other letter to cancel: "
  read ans
#taking user input to confirm removal

  if [ "$ans" == "Y" ]; then
    grep -v "$search" $file > ${file}.tmp
#put everything other than the search result contact into a tmp file

    mv ${file}.tmp ${file}
#rename the tmp file into the original file name, effectively deleting the old file with the old contact
    
    echo "The entry was removed"; echo
#message of successful removal

  else
    echo "The entry was not removed."; echo
#not removing the entry if the user does not enter Y

  fi
}



do_edit(){
    
  search_entry
  search=`head -$? $file | tail -1`
  if [ -z "${search}" ]; then
	return
  fi
#same logic as the start of do_remove...
#searches for one specific entry in the contact list and saves it in a variable

  echo "Entry to be edited: "; echo
  echo "$search" | \
  sed 's/, /##/g' | \
  awk -F ',' '   
       	{for (i = 1; i <= NF; i++) {gsub("##", ", ", $i)}} 
    	{print $1,";", $2, $3, "\n", $4, "\n", $5,",", $6,",", $7,",", $8, $9, "\n", $10, "\n", $11, "\n";}' 
#similar logic to do_remove...prints a formatted view of the entry that is to be edited

  modified_search=$(echo "$search" | sed 's/, /; /g')
#takes the entry and replaces commas with a semicolon to avoid issues with the delimiter

  IFS=',' read -r contactnum firstname lastname company address city county state zipcode phone email <<< "$modified_search"
#IFS uses comma as a delimiter and pulls these variables out from the contact that is to be edited
  
  prompt_edit() {
    local current_value=$1
    read new_value
    if [ ! -z "$new_value" ]; then
      echo "$new_value"
    else
      echo "$current_value"
    fi
  }
#function returns current value if no new value is entered

    echo "Current Contact Number is $contactnum. Enter new value (or press enter to keep the current value): "
    contactnum=$(prompt_edit "$contactnum")

    echo "Current First Name is $firstname. Enter new value (or press enter to keep the current value): "
    firstname=$(prompt_edit "$firstname")

    echo "Current Last Name is $lastname. Enter new value (or press enter to keep the current value): "
    lastname=$(prompt_edit "$lastname")

    echo "Current Company is $company. Enter new value (or press enter to keep the current value): "
    company=$(prompt_edit "$company")

    echo "Current Address is $address. Enter new value (or press enter to keep the current value): "
    address=$(prompt_edit "$address")

    echo "Current City is $city. Enter new value (or press enter to keep the current value): "
    city=$(prompt_edit "$city")

    echo "Current County is $county. Enter new value (or press enter to keep the current value): "
    county=$(prompt_edit "$county")

    echo "Current State (abbreviated) is $state. Enter new value (or press enter to keep the current value): "
    state=$(prompt_edit "$state")

    echo "Current ZIP Code is $zipcode. Enter new value (or press enter to keep the current value): "
    zipcode=$(prompt_edit "$zipcode")

    echo "Current Phone Number is $phone. Enter new value (or press enter to keep the current value): "
    phone=$(prompt_edit "$phone")

    echo "Current Email Address is $email. Enter new value (or press enter to keep the current value): "
    email=$(prompt_edit "$email")

#prompts user input for each aspect of the contact book using the predefined function

  new_contact_line="${contactnum},${firstname},${lastname},${company},${address},${city},${county},${state},${zipcode},${phone},${email}"
  sed -i "/$search/c\\$new_contact_line" "$file"
  echo "The contact has been edited"; echo
#replaces old contact line with the newly edited one

}







#SCRIPT STARTS HERE

if [ ! -f $file ]; then
  echo "$file does not exist. Now creating a new file named $file ..."
  touch $file
fi
#testing whether the contacts file exists
#creates a new contacts file if it did not already exist

select option in "List/Search" Add Edit Remove Quit; do
#creating the menu to select from, each word is 1 option
  
  case $option in
#logic to determine different responses depending on the option the user selected 
  
    "List/Search")
        do_list
        ;;
      
    Add)
      do_add
      ;;
      
    Edit)
      do_edit   
      ;;
      
    Remove)
      do_remove   
      ;;
      
    Quit)
      echo "Exiting Program..."; echo  
      break
      ;;
      
    *)                                                  
      echo "Invalid input: $REPLY. Please enter a number from 1-5."; echo 
#handling unintended inputs
      ;;
  esac
done