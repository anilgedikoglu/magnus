
/***********************************************************************************************************
 * Produced by App Advisory	- http://app-advisory.com													   *
 * Facebook: https://facebook.com/appadvisory															   *
 * Contact us: https://appadvisory.zendesk.com/hc/en-us/requests/new									   *
 * App Advisory Unity Asset Store catalog: http://u3d.as/9cs											   *
 * Developed by Gilbert Anthony Barouch - https://www.linkedin.com/in/ganbarouch                           *
 ***********************************************************************************************************/

using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;

namespace AppAdvisory.AA
{
	public class ObjectPoolingManager
	{
		private static volatile ObjectPoolingManager instance;

		private Dictionary<String, ObjectPool> objectPools;

		private static object syncRoot = new System.Object();

		private ObjectPoolingManager()
		{

			this.objectPools = new Dictionary<String, ObjectPool>();
		}


		public static ObjectPoolingManager Instance
		{
			get
			{

				if (instance == null)
				{

					lock (syncRoot)
					{

						if (instance == null)
						{

							instance = new ObjectPoolingManager();
						}
					}
				}

				return instance;
			}
		}



		public bool CreatePool(Transform objToPool, int initialPoolSize, int maxPoolSize)
		{
			return CreatePool (objToPool.gameObject, initialPoolSize, maxPoolSize);
		}
		public bool CreatePool(GameObject objToPool, int initialPoolSize, int maxPoolSize)
		{
			ObjectPoolingManager.Instance.objectPools = new Dictionary<string, ObjectPool>();

			if (ObjectPoolingManager.Instance.objectPools.ContainsKey(objToPool.name))
			{

				return false;
			}
			else
			{

				ObjectPool nPool = new ObjectPool(objToPool, initialPoolSize, maxPoolSize);

				ObjectPoolingManager.Instance.objectPools.Add(objToPool.name, nPool);

				return true;
			}
		}

		public GameObject GetObject(string objName)
		{

			return ObjectPoolingManager.Instance.objectPools[objName].GetObject();
		}

		public List<GameObject> GetObjects(string objName)
		{
			return ObjectPoolingManager.Instance.objectPools [objName].pooledObjects;
		}
	}
}