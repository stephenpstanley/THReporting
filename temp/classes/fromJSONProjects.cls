public class fromJSONProjects{
	public Integer total_count;	//57
	public cls_data[] data;
    
	class cls_data {
		public String id;	//117
		public DateTime created_at;	//2016-06-30T18:15:56.887Z
		public DateTime updated_at;	//2017-12-15T18:56:29.574Z
		public String title;	//Quick Start: Build Your First App
		public String badge_icon;	//https://developer.salesforce.com/resource/images/trailhead/badges/projects/trailhead_project_quick_start_devzone_mobile_app.png
		public String description_html;	//Create a simple app to track visits to your local park.
		public String badge_title;	//Quick Start: Build Your First App
		public String web_url;	//https://developer.salesforce.com/trailhead/en/project/quickstart-devzone-app/
		public boolean archived;
		public cls_tags[] tags;
		public cls_roles[] roles;
		public cls_products[] products;
		public cls_levels[] levels;
		public cls_steps[] steps;
	}
	class cls_tags {
		public String id;	//19
		public String title;	//App Logic
	}
	class cls_roles {
		public String id;	//28
		public String title;	//Admin
	}
	class cls_products {
		public String id;	//35
		public String title;	//Salesforce Platform
	}
	class cls_levels {
		public String id;	//42
		public String title;	//Beginner
	}
	class cls_steps {
		public String id;	//25635
		public DateTime created_at;	//2018-02-14T19:46:32.610Z
		public DateTime updated_at;	//2018-02-14T19:46:45.397Z
		public String title;	//Create the Trailblazer App
		public String description_html;
		public Integer challenge_time;	//5
		public Integer total_points;	//25
		public boolean archived;
		public String web_url;	//https://developer.salesforce.com/trailhead/en/project/quickstart-devzone-app/devzone-app-1/
		public cls_tags[] tags;
		public cls_roles[] roles;
		public cls_products[] products;
		public cls_levels[] levels;
	}

	public static fromJSONProjects parse(String json){
		return (fromJSONProjects) System.JSON.deserialize(json, fromJSONProjects.class);
	}

}