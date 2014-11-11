package de.fltdpl.qmansis;

import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.telephony.SmsManager;

public class Status extends ActionBarActivity {
	
	Button status;
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_status);
        
        status = (Button) findViewById(R.id.button_status);
        status.setOnClickListener(new View.OnClickListener() {
        	
        	public void onClick(View v) {
        		sendSMS();
        	}
        		
        });
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.status, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        if (id == R.id.action_settings) {
        	
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
    
    
    public void sendSMS() {
    	String Telnummer    = "017663119724";
    	String Telnachricht = "Piepender Spatz";
    	
    	SmsManager smsManager = SmsManager.getDefault();
    	smsManager.sendTextMessage(Telnummer, null, Telnachricht, null, null);
    	
    }
}
