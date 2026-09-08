@IsTest
private class CPQQuoteProposalOutputSerializerTest {
    @IsTest
    static void aggregatesGroupsIntoOneRootObject() {
        List<Object> rows = new List<Object>{
            new Map<String, Object>{
                'AccountName' => 'Example',
                'Group' => new Map<String, Object>{
                    'Name' => 'Year 1',
                    'Line' => new List<Object>{new Map<String, Object>{'ProductName' => 'A'}}
                }
            },
            new Map<String, Object>{
                'AccountName' => 'Example',
                'Group' => new Map<String, Object>{
                    'Name' => 'Year 2',
                    'Line' => new List<Object>{new Map<String, Object>{'ProductName' => 'B'}}
                }
            }
        };
        Map<String, Object> input = new Map<String, Object>{'input' => rows};
        Map<String, Object> output = new Map<String, Object>();
        CPQQuoteProposalOutputSerializer serializer = new CPQQuoteProposalOutputSerializer();
        System.assertEquals(true, serializer.invokeMethod(
            'serialize', input, output, new Map<String, Object>()
        ));

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped((String) output.get('output'));
        System.assertEquals('Example', result.get('AccountName'));
        System.assertEquals(2, ((List<Object>) result.get('Group')).size());
    }

    @IsTest
    static void preservesNonListInput() {
        Map<String, Object> inputValue = new Map<String, Object>{'AccountName' => 'Example'};
        Map<String, Object> output = new Map<String, Object>();
        CPQQuoteProposalOutputSerializer serializer = new CPQQuoteProposalOutputSerializer();
        System.assertEquals(true, serializer.serialize(
            new Map<String, Object>{'input' => inputValue}, output
        ));
        System.assertEquals('{"AccountName":"Example"}', output.get('output'));
    }

    @IsTest
    static void callableContractAndEmptyList() {
        Map<String, Object> output = new Map<String, Object>();
        CPQQuoteProposalOutputSerializer serializer = new CPQQuoteProposalOutputSerializer();
        System.assertEquals(true, serializer.call('serialize', new Map<String, Object>{
            'input' => new Map<String, Object>{'input' => new List<Object>()},
            'output' => output,
            'options' => new Map<String, Object>()
        }));
        System.assertEquals('{"Group":[]}', output.get('output'));
        System.assertEquals(false, serializer.invokeMethod(
            'unsupported', new Map<String, Object>(), new Map<String, Object>(), new Map<String, Object>()
        ));
    }
}
