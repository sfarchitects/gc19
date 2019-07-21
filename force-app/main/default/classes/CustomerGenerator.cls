/**
 * Knows how to generate fake Customer records.
 */
public with sharing class CustomerGenerator implements Queueable {

	public static final Integer MONTHS_OF_DATA = 24;

	private final Integer howMany;
	private final Integer fileNumber;
	private final Integer offset;

	private List<Account> accountsToInsert = new List<Account>();
	private List<Contact> contactsToInsert = new List<Contact>();
	private List<Order_Summary__c> orderSummariesToInsert = new List<Order_Summary__c>();

	private Map<String, Id> recordTypes {
		get {
			if(recordTypes == null) {
				recordTypes = new Map<String, Id>();
				for(RecordType recordType : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
					recordTypes.put(recordType.DeveloperName, recordType.Id);
				}
			}
			return recordTypes;
		}
		set;
	}

	public CustomerGenerator(Integer howMany, Integer fileNumber, Integer offset) {
		this.howMany = howMany;
		this.fileNumber = fileNumber;
		this.offset = offset;
	}

	public void execute(QueueableContext qc) {

		/*
		 * Grab data from one of our dummy data files, and parse it into useful records.
		 */
		String resourceName = 'customers' + fileNumber;
		List<List<String>> records = CsvReader.readIETFRFC4180CSVFile([SELECT Body FROM StaticResource WHERE Name = :resourceName].Body);
		System.debug(LoggingLevel.WARN, records.size());
		records.remove(0); // drop the header row
		for(Integer i = offset, j = offset + howMany; i < j; i++) {
			parseRow(records[i]);
		}

		if(!accountsToInsert.isEmpty()) {
			insert accountsToInsert;
		}

		if(!contactsToInsert.isEmpty()) {
			for(Contact c : contactsToInsert) {
				c.AccountId = c.Account.Id; // copy the Id value over now that the parent Account was persisted
			}
			insert contactsToInsert;
		}

		if(!orderSummariesToInsert.isEmpty()) {
			for(Order_Summary__c summary : orderSummariesToInsert) {
				summary.Customer__c = summary.Customer__r.Id; // copy the Id value over now that the parent Account was persisted
			}
			insert orderSummariesToInsert;
		}
	}

	private void parseRow(List<String> cells) {

		// id(0),first_name(1),last_name(2),email(3),company(4),phone(5),street(6),city(7),state(8),country(9),postal_code(10),commercial(11)

		// determine if this is a commercial customer or an individual
		Boolean isCommercial = Boolean.valueOf(cells[11]);

		// set up the Account record
		Account customer = new Account(
			Name = isCommercial ? cells[4] : cells[2] + ', ' + cells[1],
			RecordTypeId = isCommercial ? recordTypes.get('Commercial') : recordTypes.get('Individual'),
			BillingStreet = cells[6],
			BillingCity = cells[7],
			BillingCountry = cells[9],
			BillingPostalCode = cells[10],
			Phone = cells[5]
		);
		accountsToInsert.add(customer);

		// if individual, set up a Contact record
		if(!isCommercial) {
			contactsToInsert.add(
				new Contact(
					FirstName = cells[1],
					LastName = cells[2],
					Email = cells[3],
					Phone = cells[5],
					Account = customer
				)
			);
		}

		//set up Order Summary records
		buildOrderSummaries(customer);
	}

	private void buildOrderSummaries(Account customer) {

		for(Integer i = 1; i <= MONTHS_OF_DATA; i++) {
			Datetime marker = System.now().addMonths(-1 * i);
			orderSummariesToInsert.add(
				new Order_Summary__c(
					Name = marker.yearGmt() + '-' + marker.monthGmt(),
					Start_of_Period__c = marker.date().toStartOfMonth(),
					End_of_Period__c = marker.date().toStartOfMonth().addDays(Date.daysInMonth(marker.yearGmt(), marker.monthGmt())),
					Customer__r = customer,
					Number_of_Orders__c = (100 * Math.random()).intValue(),
					Value_of_Goods_Sold__c = (10000 * Math.random()).intValue()
				)
			);
		}
	}
}