/// Merge two JSON objects
///
/// This is used to merge the config files, so that the user can override the default config.
/// Arrays are replaced, not merged.
///
/// Copypasted from https://stackoverflow.com/a/67730632
pub fn merge_json(a: &mut serde_json::Value, b: &serde_json::Value) {
	match (a, b) {
		(a @ &mut serde_json::Value::Object(_), serde_json::Value::Object(b)) => {
			let a = a.as_object_mut().unwrap();
			for (k, v) in b {
				if v.is_array() && a.contains_key(k) && a.get(k).as_ref().unwrap().is_array() {
					let mut _a = a.get(k).unwrap().as_array().unwrap().to_owned();
					v.as_array().unwrap().clone_into(&mut _a);
					a[k] = serde_json::Value::from(_a);
				} else {
					merge_json(a.entry(k).or_insert(serde_json::Value::Null), v);
				}
			}
		}
		(a, b) => *a = b.clone(),
	}
}

#[cfg(test)]
mod tests {
	use super::*;
	use serde_json::json;

	#[test]
	fn test_merge_json() {
		let mut a = json!({
			"foo": "bar",
			"bar": {
				"foo": "bar",
				"bar": "foo",
				"baz": {
					"foo": "bar",
					"bar": "foo",
				},
			},
			"baz": {
				"foo": "bar",
				"bar": "foo",
			},
			"zab": ["foo", "bar"]
		});
		let b = json!({
			"foo": "foo",
			"bar": {
				"foo": "foo",
				"baz": {
					"foo": "foo",
				},
			},
			"baz": ["foo", "bar"],
			"zab": ["baz"]
		});
		merge_json(&mut a, &b);
		assert_eq!(
			a,
			json!({
				"foo": "foo",
				"bar": {
					"foo": "foo",
					"bar": "foo",
					"baz": {
						"foo": "foo",
						"bar": "foo",
					},
				},
				"baz": ["foo", "bar"],
				"zab": ["baz"]
			})
		);
	}
}
