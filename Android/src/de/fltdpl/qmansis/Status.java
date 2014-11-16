package de.fltdpl.qmansis;

import android.support.v7.app.ActionBarActivity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.telephony.SmsManager;

public class Status extends ActionBarActivity {
	
	Button status;
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// TODO Auto-generated method stub
		switch(item.getItemId()){
		case R.id.about:
			Intent i = new Intent("de.fltdpl.qmansis.ABOUT");
			startActivity(i);
			
			break;
		case R.id.action_settings:
			Intent s = new Intent("de.fltdpl.qmansis.SETTINGS");
			startActivity(s);
			
			break;
		}
		return false;
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// TODO Auto-generated method stub
		super.onCreateOptionsMenu(menu);
		MenuInflater blowUp = getMenuInflater();
		blowUp.inflate(R.menu.status, menu);
		return true;
	}

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_status);
        
        status = (Button) findViewById(R.id.button_status);
        status.setOnClickListener(new View.OnClickListener() {
        	
        	public void onClick(View v) {
        		sendSMS_STATUS();
        	}
        		
        });
    }
    
    public void sendSMS_STATUS() {
    	
    	SharedPreferences getPrefs = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
    	String Telnummer    = getPrefs.getString("editnumber_preference", "0");
    	//String Telnummer    = "017663119724";
    	String Telnachricht = "STATUS";
    	
    	SmsManager smsManager = SmsManager.getDefault();
    	smsManager.sendTextMessage(Telnummer, null, Telnachricht, null, null);
    	
    }
    
    
    
}
