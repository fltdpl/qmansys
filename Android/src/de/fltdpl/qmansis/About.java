package de.fltdpl.qmansis;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

public class About extends Activity{
	
	TextView Github;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.about);
		
		Github = (TextView) findViewById(R.id.textView_about_2);
		Github.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/fltdpl/qmansys"));
				startActivity(browserIntent);
			}
		});	
	}
}
