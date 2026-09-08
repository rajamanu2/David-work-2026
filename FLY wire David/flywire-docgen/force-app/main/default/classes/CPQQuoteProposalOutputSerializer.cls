global with sharing class CPQQuoteProposalOutputSerializer implements Callable, omnistudio.VlocityOpenInterface2 {
    global Object call(String action, Map<String, Object> args) {
        return invokeMethod(
            action,
            (Map<String, Object>) args.get('input'),
            (Map<String, Object>) args.get('output'),
            (Map<String, Object>) args.get('options')
        );
    }

    global Object invokeMethod(
        String methodName,
        Map<String, Object> input,
        Map<String, Object> output,
        Map<String, Object> options
    ) {
        if (methodName == 'serialize') {
            return serialize(input, output);
        }
        return false;
    }

    global Boolean serialize(Map<String, Object> input, Map<String, Object> output) {
        Object raw = input.get('input');
        Object normalized = normalize(raw);
        output.put('output', JSON.serialize(normalized));
        return true;
    }

    @TestVisible
    private static Object normalize(Object raw) {
        if (!(raw instanceof List<Object>)) {
            return raw;
        }

        List<Object> rows = (List<Object>) raw;
        if (rows.isEmpty()) {
            return new Map<String, Object>{'Group' => new List<Object>()};
        }

        Map<String, Object> root = new Map<String, Object>();
        List<Object> groups = new List<Object>();
        for (Object rowValue : rows) {
            if (!(rowValue instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> row = (Map<String, Object>) rowValue;
            if (root.isEmpty()) {
                root.putAll(row);
                root.remove('Group');
            }
            if (row.containsKey('Group') && row.get('Group') != null) {
                groups.add(row.get('Group'));
            }
        }
        root.put('Group', groups);
        return root;
    }
}
