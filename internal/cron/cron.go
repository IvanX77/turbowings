package cron

import (
	"context"
	"time"

	"emperror.dev/errors"
	"github.com/apex/log"
	"github.com/go-co-op/gocron/v2"

	"github.com/IvanX77/turbowings/config"
	"github.com/IvanX77/turbowings/server"
	"github.com/IvanX77/turbowings/system"
)

const ErrCronRunning = errors.Sentinel("cron: job already running")

var o system.AtomicBool

// Scheduler configures the internal cronjob system for TurboWings and returns the scheduler
// instance to the caller. This should only be called once per application lifecycle, additional
// calls will result in an error being returned.
func Scheduler(ctx context.Context, m *server.Manager) (gocron.Scheduler, error) {
	if !o.SwapIf(true) {
		return nil, errors.New("cron: cannot call scheduler more than once in application lifecycle")
	}

	location, err := time.LoadLocation(config.Get().System.Timezone)
	if err != nil {
		return nil, errors.Wrap(err, "cron: failed to parse configured system timezone")
	}

	s, err := gocron.NewScheduler(
		gocron.WithLocation(location),
	)
	if err != nil {
		return nil, errors.Wrap(err, "cron: failed to create scheduler")
	}

	activity := activityCron{
		mu:      system.NewAtomicBool(false),
		manager: m,
		max:     config.Get().System.ActivitySendCount,
	}

	sftp := sftpCron{
		mu:      system.NewAtomicBool(false),
		manager: m,
		max:     config.Get().System.ActivitySendCount,
	}

	l := log.WithField("subsystem", "cron")

	interval := time.Duration(config.Get().System.ActivitySendInterval) * time.Second
	l.WithField("interval", interval).Info("configuring system crons")

	// Activity job
	_, err = s.NewJob(
		gocron.DurationJob(interval),
		gocron.NewTask(func() {
			l.WithField("cron", "activity").Debug("sending internal activity events to Panel")
			if err := activity.Run(ctx); err != nil {
				if errors.Is(err, ErrCronRunning) {
					l.WithField("cron", "activity").Warn("activity process is already running, skipping...")
				} else {
					l.WithField("cron", "activity").WithField("error", err).Error("activity process failed to execute")
				}
			}
		}),
	)
	if err != nil {
		return nil, errors.Wrap(err, "cron: failed to create activity job")
	}

	// SFTP job
	_, err = s.NewJob(
		gocron.DurationJob(interval),
		gocron.NewTask(func() {
			l.WithField("cron", "sftp").Debug("sending sftp events to Panel")
			if err := sftp.Run(ctx); err != nil {
				if errors.Is(err, ErrCronRunning) {
					l.WithField("cron", "sftp").Warn("sftp events process already running, skipping...")
				} else {
					l.WithField("cron", "sftp").WithField("error", err).Error("sftp events process failed to execute")
				}
			}
		}),
	)
	if err != nil {
		return nil, errors.Wrap(err, "cron: failed to create sftp job")
	}

	return s, nil
}
