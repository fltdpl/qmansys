package de.fltdpl.qmansis;

import android.bluetooth.BluetoothAdapter;
import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.ActionBarActivity;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.Toast;

public class Bluetooth extends ActionBarActivity{
	
	BluetoothAdapter btAdapter;
	
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// TODO Auto-generated method stub
		switch(item.getItemId()){
		case R.id.status:
			Intent m1 = new Intent("de.fltdpl.qmansis.STATUS");
			startActivity(m1);
			
			break;
		case R.id.about:
			Intent m3 = new Intent("de.fltdpl.qmansis.ABOUT");
			startActivity(m3);
			
			break;
		case R.id.action_settings:
			Intent m4 = new Intent("de.fltdpl.qmansis.SETTINGS");
			startActivity(m4);
			
			break;
		}
		return false;
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// TODO Auto-generated method stub
		super.onCreateOptionsMenu(menu);
		MenuInflater blowUp = getMenuInflater();
		blowUp.inflate(R.menu.bluetooth, menu);
		return true;
	}
	
	 @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_bluetooth);
	        
	        btAdapter = BluetoothAdapter.getDefaultAdapter();		// Init Bluetoothadapter
	        if(btAdapter == null){									// Wenn kein Bluetooth vorhanden ist
	        	Toast.makeText(getApplicationContext(), "Kein Bluetooth erkannt.", 0).show();
	        	finish();
	        } else {												// Bluetooth vorhanden
	        	if(!btAdapter.isEnabled()){							// Bluetooth ausgeschaltet?
	        		Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE); // Bluetooth anschalten
	        		startActivityForResult(intent, 1);
	        	}
	        }
	        
	 }
	 
	 @Override
	 protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		 super.onActivityResult(requestCode, resultCode, data);
		 if(resultCode == RESULT_CANCELED){
			 Toast.makeText(getApplicationContext(), "Bluetooth muss eingeschaltet sein.", Toast.LENGTH_SHORT).show();
			 finish();
		 }
	 }
	

}
