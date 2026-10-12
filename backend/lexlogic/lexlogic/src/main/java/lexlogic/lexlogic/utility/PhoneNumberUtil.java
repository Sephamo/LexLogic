package lexlogic.lexlogic.utility;

public class PhoneNumberUtil {

    public static String normalizePhoneNumber(String phoneNumber){

        if (phoneNumber == null) {
            throw new IllegalArgumentException("Phone number is required");
        }

        // Remove spaces and hyphens
        phoneNumber = phoneNumber.replaceAll("[\\s-]", "");

        // Convert 06/07/08xxxxxxxx to +276/277/278xxxxxxxx
        if (phoneNumber.matches("^0[6-8][0-9]{8}$")) {
            phoneNumber = "+27" + phoneNumber.substring(1);
        }

        // Validate final format
        if (!phoneNumber.matches("^\\+27[6-8][0-9]{8}$")) {
            throw new IllegalArgumentException("Invalid South African phone number");
        }

        return phoneNumber;
    }
}
