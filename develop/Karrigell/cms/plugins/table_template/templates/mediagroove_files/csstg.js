/* Google Stuff */

google_ad_client = "pub-6730206592365449";
google_ad_width = 120;
google_ad_height = 600;
google_ad_format = "120x600_as";
google_ad_type = "text";
google_ad_channel ="";
google_color_border = "CCCCCC";
google_color_bg = "FFFFFF";
google_color_link = "000000";
google_color_url = "666666";
google_color_text = "333333";
		function validate(f){
			if(!document.getElementById('error'))
			{
				var er=document.createElement('div');
				er.id='error';
				er.className='error';
				document.getElementsByTagName('form')[0].parentNode.insertBefore(er,document.getElementsByTagName('form')[0])
			}
			var errorlist='';
			var man=document.getElementById('mandatory').value.split(',');
			for (var i=0;i<man.length;i++){
				if (document.getElementById(man[i]).value=='')
				{
					document.getElementById(man[i]).style.background='#f99';
					errorlist+='<li>'+man[i]+' is empty</li>';
				}
			}
			if (!isEmailAddr(document.getElementById('email').value))
			{
				document.getElementById('email').style.background='#f99';
				errorlist+='<li>Your email seems to be invalid</li>';
			}
			if(errorlist=='')
			{
				return true;
			} else {
				var errmsg='<h3><a href="#" id="errorheader">I encountered the following errors:</a></h3>';
				errmsg+='<ul>'+errorlist+'</ul>';
				document.getElementById('error').innerHTML=errmsg;
				document.getElementById('errorheader').focus();
				return false;
			}
		}
		function isEmailAddr(str) 
		{
		    return str.match(/^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$/);
		}
				
