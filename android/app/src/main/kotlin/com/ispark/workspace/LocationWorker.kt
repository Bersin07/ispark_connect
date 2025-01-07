package com.ispark.workspace

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.ktx.Firebase
import com.google.firebase.ktx.initialize
import com.google.android.gms.location.LocationServices
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.coroutineScope

class LocationWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = coroutineScope {
        try {
            Firebase.initialize(applicationContext)
            val user = FirebaseAuth.getInstance().currentUser

            if (user != null) {
                val position = LocationServices
                    .getFusedLocationProviderClient(applicationContext)
                    .lastLocation
                    .await()

                if (position != null) {
                    FirebaseFirestore.getInstance()
                        .collection("users")
                        .document(user.uid)
                        .collection("live_location")
                        .add(
                            hashMapOf(
                                "latitude" to position.latitude,
                                "longitude" to position.longitude,
                                "timestamp" to FieldValue.serverTimestamp()
                            )
                        )
                }
            }
            Result.success()
        } catch (e: Exception) {
            Result.failure()
        }
    }
}
