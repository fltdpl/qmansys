package de.fltdpl.qmansis;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.telephony.SmsManager;
import android.telephony.SmsMessage;
import android.util.Log;
import android.widget.Toast;


public class SmsReceiver extends BroadcastReceiver {
	
	// Get the object of SmsManager
    final SmsManager sms = SmsManager.getDefault();

	@Override
	public void onReceive(Context context, Intent intent) {
		
		// Retrieves a map of extended data from the intent.
        final Bundle bundle = intent.getExtras();
 
        try {
             
            if (bundle != null) {
                 
                final Object[] pdusObj = (Object[]) bundle.get("pdus");
                 
                for (int i = 0; i < pdusObj.length; i++) {
                     
                    SmsMessage currentMessage = SmsMessage.createFromPdu((byte[]) pdusObj[i]);
                    String phoneNumber = currentMessage.getOriginatingAddress();
                    String message = currentMessage.getMessageBody().toString();
 
                    Log.i("SmsReceiver", "senderNum: "+ phoneNumber + "; message: " + message);
                    
                    // Nummer pruefen
                    SharedPreferences getPrefs = PreferenceManager.getDefaultSharedPreferences(context);
                	String Telnummer    = getPrefs.getString("editnumber_preference", "0");
                    
                    if (Telnummer.equals(phoneNumber)) {
                    	// Show Alert
                        //int duration = Toast.LENGTH_LONG;
                        //Toast toast = Toast.makeText(context,
                        //             "senderNum: "+ senderNum + ", message: " + message, duration);
                        //toast.show();
                    	
                        // A custom Intent that will used as another Broadcast
                        Intent in = new Intent("SmsMessage.intent.STATUS").putExtra(
                                "get_msg", phoneNumber + ":" + message);

                        // send another broadcast
                        context.sendBroadcast(in);
                    }
                } // end for loop
              } // bundle is null
 
        } catch (Exception e) {
            Log.e("SmsReceiver", "Exception smsReceiver" +e);
             
        }	
		

		
	}
	

}
