/**
 * Generates records to support exercises in this repo.
 */
public with sharing class DataGenerator {

	public static void populateDataModel() {

		populateAccountTiers();
		populateCustomersAndOrderSummaries();
	}

	private static void populateAccountTiers() {

		insert new List<Tier__c>{
			new Tier__c(Name='Bronze',Discount__c=0.00),
			new Tier__c(Name='Silver',Discount__c=0.01),
			new Tier__c(Name='Gold',Discount__c=0.03)
		};
	}

	private static void populateCustomersAndOrderSummaries() {

		// we have to break this out into a few execution contexts to get all the records we want (100,000 records)
		System.enqueueJob(new CustomerGenerator(384,1,0));
		System.enqueueJob(new CustomerGenerator(384,1,384));
		System.enqueueJob(new CustomerGenerator(232,1,768));
		System.enqueueJob(new CustomerGenerator(384,2,0));
		System.enqueueJob(new CustomerGenerator(384,2,384));
		System.enqueueJob(new CustomerGenerator(232,2,768));
		System.enqueueJob(new CustomerGenerator(384,3,0));
		System.enqueueJob(new CustomerGenerator(384,3,384));
		System.enqueueJob(new CustomerGenerator(232,3,768));
		System.enqueueJob(new CustomerGenerator(384,4,0));
		System.enqueueJob(new CustomerGenerator(384,4,384));
		System.enqueueJob(new CustomerGenerator(232,4,768));
	}

}